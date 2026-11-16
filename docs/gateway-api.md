# Gateway API

The AWS Load Balancer Controller implements [Gateway API](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/gateway/gateway/). A `GatewayClass` with controller name `gateway.k8s.aws/alb` gets an ALB for `HTTPRoute`s and `GRPCRoute`s, and one with `gateway.k8s.aws/nlb` gets an NLB for `TCPRoute`s, `UDPRoute`s and `TLSRoute`s.

## Prerequisites

- The Gateway API CRDs, v1.6 or newer. Install them in the workload cluster with the `gateway-api-crds` app (v1.9.0 or newer), or with the `gateway-api-bundle`. The controller only turns on its Gateway API support if these CRDs exist, so install them first, or restart the controller after installing them.
- The controller's own CRDs (`LoadBalancerConfiguration`, `TargetGroupConfiguration` and `ListenerRuleConfiguration` in group `gateway.k8s.aws`). The bundle installs them with the controller.

## Example

An internet-facing ALB that routes all requests to the `echo` `Service`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: aws-alb
spec:
  controllerName: gateway.k8s.aws/alb
---
apiVersion: gateway.k8s.aws/v1
kind: LoadBalancerConfiguration
metadata:
  name: echo
  namespace: default
spec:
  # The default is `internal`
  scheme: internet-facing
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: echo
  namespace: default
spec:
  gatewayClassName: aws-alb
  infrastructure:
    parametersRef:
      group: gateway.k8s.aws
      kind: LoadBalancerConfiguration
      name: echo
  listeners:
    - name: http
      protocol: HTTP
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo
  namespace: default
spec:
  parentRefs:
    - name: echo
  rules:
    - backendRefs:
        - name: echo
          port: 8080
```

With the default target type `instance`, the `echo` `Service` must be of type `NodePort`. To send traffic to the pods directly, for example on [EKS clusters](eks.md), set the target type `ip` with a `TargetGroupConfiguration`:

```yaml
apiVersion: gateway.k8s.aws/v1
kind: TargetGroupConfiguration
metadata:
  name: echo
  namespace: default
spec:
  targetReference:
    name: echo
  defaultConfiguration:
    targetType: ip
```

The `Gateway`'s `status.addresses` shows the DNS name of the load balancer once it exists.
