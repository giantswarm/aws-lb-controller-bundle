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
  version: 3.0.0
```

The bundle chart will:

1. Create the necessary IAM role with proper permissions using Crossplane
2. Deploy the AWS Load Balancer Controller to the workload cluster using a Flux HelmRelease

## Upgrade from v2.x.x to v3.x.x

v3.x.x introduces a breaking change: a new installation method for the app. Please review the [v3 release notes](https://github.com/giantswarm/aws-load-balancer-controller-app/releases/tag/v3.0.0) for detailed upgrade instructions and migration steps.
