[![CircleCI](https://circleci.com/gh/giantswarm/aws-load-balancer-controller-app/tree/main.svg?style=svg)](https://circleci.com/gh/giantswarm/aws-load-balancer-controller-app/tree/main)

# AWS Load Balancer Controller chart

Giant Swarm offers an `aws-lb-controller-bundle` Managed App which can be installed in tenant clusters.
Here we define the `aws-lb-controller-bundle` and `aws-load-balancer-controller` charts with their templates and default configuration.

- [AWS Load Balancer Controller chart](#aws-load-balancer-controller-chart)
  - [Introduction](#introduction)
  - [Architecture](#architecture)
  - [Prerequisites](#prerequisites)
  - [Installing](#installing)
  - [Upgrade from v2.x.x to v3.x.x](#upgrade-from-v2xx-to-v3xx)

## Introduction
[AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/) controller manages the following AWS resources
- Application Load Balancers to satisfy Kubernetes ingress objects
- Network Load Balancers to satisfy Kubernetes service objects of type LoadBalancer with appropriate annotations

## Architecture

This repository contains two Helm charts:

- `helm/aws-lb-controller-bundle/`: Main chart installed on the management cluster, contains the workload cluster chart and the required AWS IAM role.
- `helm/aws-load-balancer-controller/`: Workload cluster chart that contains the actual AWS Load Balancer Controller setup.

Users only need to install the bundle chart on the management cluster, which in turn will deploy the workload cluster chart.

## Prerequisites

The controller runs on the worker nodes and needs access to AWS ALB/NLB resources via IAM permissions. When using the bundle chart, the IAM role is automatically created using Crossplane.

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
