[![CircleCI](https://circleci.com/gh/giantswarm/aws-load-balancer-controller-app/tree/main.svg?style=svg)](https://circleci.com/gh/giantswarm/aws-load-balancer-controller-app/tree/main)

# AWS Load Balancer Controller chart

Giant Swarm offers an `aws-lb-controller-bundle` Managed App which can be installed in tenant clusters.
Here we define the `aws-lb-controller-bundle` and `aws-load-balancer-controller` charts with their templates and default configuration.

## Key terminology

| Term | Where it lives | What it does |
|------|---------------|--------------|
| **Bundle-only** | Management cluster only | Never forwarded to the workload chart. Examples: `ociRepositoryUrl`, `clusterName` (used for IRSA computation) |
| **Upstream** | Workload cluster, under `upstream:` key | Routed to the unmodified upstream sub-chart. Controls the actual controller: image, replicas, resources, service account, etc. |
| **Extras** | Workload cluster, at top level (not under `upstream:`) | Consumed by GS extras templates: `networkPolicy`, `verticalPodAutoscaler`, `global.podSecurityStandards` |

## Architecture

```
Management Cluster (bundle chart)          Workload Cluster (workload chart)
┌──────────────────────────────────┐       ┌──────────────────────────────────┐
│  App CR (aws-lb-controller-      │       │                                  │
│          bundle)                 │       │  ┌────────────────────────────┐  │
│         │                        │       │  │ upstream sub-chart         │  │
│         ▼                        │       │  │ (aws-load-balancer-        │  │
│  ┌─────────────┐                 │       │  │  controller v3.0.0)       │  │
│  │ IAM Role    │ Crossplane      │       │  │  • Deployment             │  │
│  │ (IRSA)      │                 │       │  │  • Service                │  │
│  └─────────────┘                 │       │  │  • RBAC, Webhooks, etc.   │  │
│  ┌─────────────┐                 │       │  └────────────────────────────┘  │
│  │ ConfigMap   │ workloadValues  │       │  ┌────────────────────────────┐  │
│  │ (values)    │─────────────────│───────│─▶│ GS extras                 │  │
│  └─────────────┘                 │       │  │  • NetworkPolicy          │  │
│  ┌─────────────┐                 │       │  │  • VPA                    │  │
│  │ HelmRelease │ Flux            │       │  │  • PSS Exceptions         │  │
│  │ + OCIRepo   │─────────────────│───────│─▶│                           │  │
│  └─────────────┘                 │       │  └────────────────────────────┘  │
└──────────────────────────────────┘       └──────────────────────────────────┘
```

### Charts

| Chart | Location | Deployed to | Purpose |
|-------|----------|-------------|---------|
| `aws-lb-controller-bundle` | `helm/aws-lb-controller-bundle/` | Management cluster | Orchestrator. Creates IAM role (Crossplane), Flux resources (OCIRepository + HelmRelease), and a ConfigMap with computed values. |
| `aws-load-balancer-controller` | `helm/aws-load-balancer-controller/` | Workload cluster (via Flux) | Wraps the unmodified upstream chart as a Helm dependency (alias `upstream`) and adds GS-specific extras templates. |

### Value flow

1. The bundle chart's `values.yaml` contains three sections: **bundle-only**, **upstream**, and **extras**.
2. The `giantswarm.workloadValues` helper in the bundle's `_helpers.tpl` transforms these flat values:
   - **Image**: Combines split `registry` + `name` (GS format) into a single `repository` path expected by the upstream chart.
   - **IRSA**: Computes the IAM role ARN from the `crossplane-config` ConfigMap and injects it into `serviceAccount.annotations`.
   - **Cluster tags**: Sets `defaultTags` with cluster ownership tags.
   - **Upstream routing**: All upstream values are placed under the `upstream:` key.
   - **Extras routing**: `verticalPodAutoscaler` and `global` are passed at top level (not under `upstream:`).
   - **Bundle-only exclusion**: `ociRepositoryUrl`, `bundleNameOverride`, and `fullBundleNameOverride` are never forwarded.
3. The transformed values are stored in a ConfigMap on the management cluster.
4. A Flux HelmRelease references this ConfigMap via `valuesFrom` and deploys the workload chart to the workload cluster.

### Why this pattern

- **Unmodified upstream** — Version bumps require only updating the dependency version and running `helm dependency update`. No fork maintenance.
- **Separation of concerns** — IAM and Flux orchestration live on the management cluster; the application runs on the workload cluster.
- **Single App CR** — Users install the bundle once on the management cluster; everything else is automated.

## Prerequisites

The controller runs on worker nodes and needs access to AWS ALB/NLB resources via IAM permissions. When using the bundle chart, the IAM role is automatically created using Crossplane.

## Installing

Install the bundle chart on the management cluster using an App CR:

```yaml
apiVersion: application.giantswarm.io/v1alpha1
kind: App
metadata:
  name: coyote-aws-lb-controller-bundle
  namespace: org-acme
spec:
  catalog: giantswarm
  config:
    configMap:
      name: coyote-cluster-values
      namespace: org-acme
  kubeConfig:
    inCluster: true
  name: aws-lb-controller-bundle
  namespace: org-acme
  version: 4.0.0
```

The bundle chart will:

1. Create the necessary IAM role with proper permissions using Crossplane
2. Deploy the AWS Load Balancer Controller to the workload cluster using a Flux HelmRelease

## Upgrade from v2.x.x to v3.x.x

v3.x.x introduces a breaking change: a new installation method for the app. Please review the [v3 release notes](https://github.com/giantswarm/aws-load-balancer-controller-app/releases/tag/v3.0.0) for detailed upgrade instructions and migration steps.

## Upgrade to upstream dependency model

This version migrates from a forked upstream Helm chart to using the **unmodified upstream chart as a Helm dependency**. Key changes:

- The workload chart (`helm/aws-load-balancer-controller/`) no longer contains forked upstream templates. Instead, the upstream chart is declared as a dependency with alias `upstream`.
- All upstream values must now be placed under the `upstream:` key in the workload chart's values.
- The bundle chart's `_helpers.tpl` handles the value transformation automatically, so **no changes are needed for bundle chart users**.
- GS extras (NetworkPolicy, VPA, PSS exceptions) remain as separate templates in the workload chart.

## Testing

### E2E tests

End-to-end tests live in `tests/e2e/` and use the [apptest-framework](https://github.com/giantswarm/apptest-framework). They install the bundle on a CAPA management cluster and validate that the AWS Load Balancer Controller is functional on a workload cluster.

**What the tests cover:**

1. The bundle's HelmRelease reaches Ready on the MC.
2. A Service of type `LoadBalancer` is created on the WC.
3. The controller provisions a real AWS NLB and populates the Service status with its hostname.
4. The controller adds its finalizer (`service.k8s.aws/resources`) to the Service.

**From CI:**

```
/run app-test-suites
```

**Locally (against an existing cluster):**

The apptest-framework requires `E2E_KUBECONFIG_CONTEXT` to match a known provider name (`capa`, `eks`, `capv`, `capz`, etc.), so you need a kubeconfig where the MC context is named accordingly.

1. Create a kubeconfig with the correct context name:

```bash
# Login to the MC with a context named "capa"
KUBECONFIG=/tmp/e2e-kubeconfig.yaml tsh kube login <mc-name> --set-context-name=capa
```

2. Set environment variables:

```bash
export E2E_KUBECONFIG="/tmp/e2e-kubeconfig.yaml"
export E2E_KUBECONFIG_CONTEXT="capa"
export E2E_APP_VERSION="<chart-version-from-test-catalog>"

# To reuse an existing workload cluster (skip cluster creation):
export E2E_WC_NAME="<cluster-name>"
export E2E_WC_NAMESPACE="org-<org-name>"
export E2E_WC_KEEP="true"  # Prevent cluster deletion after tests
```

3. Compile and run the test binary (the framework finds `config.yaml` relative to the binary, so `go test` alone won't work):

```bash
cd tests/e2e
go test -c -o suites/basic/basic.test ./suites/basic/
cd suites/basic
./basic.test -test.v -test.timeout 60m
```

**Finding the chart version:**

For branch builds, check the test catalog for the version corresponding to your commit:

```bash
curl -s "https://giantswarm.github.io/giantswarm-test-catalog/index.yaml" | grep -A5 "aws-lb-controller-bundle:"
```

For tagged releases, use the version from `giantswarm-catalog` (e.g. `6.0.0`).

## Credit

- [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)
- [Upstream Helm chart](https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller)
