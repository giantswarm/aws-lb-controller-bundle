# EKS clusters

The bundle works on EKS workload clusters (`cluster-eks`) the same way as on CAPA clusters. The `<cluster>-crossplane-config` ConfigMap contains the EKS OIDC provider, so the IAM role trusts the controller's service account through IRSA, and it contains the region and VPC ID.

## Target type

`cluster-eks` runs Cilium in ENI mode, so pods get IP addresses from the VPC. Load balancers can therefore send traffic straight to the pods with target type `ip`, for example by setting `defaultTargetType: ip` in the bundle values or per `Service`, `Ingress` or Gateway API route. The default target type `instance` also works and sends traffic to a node port.

## Subnets

The controller finds subnets by their tags: public subnets need `kubernetes.io/role/elb: 1`, private subnets `kubernetes.io/role/internal-elb: 1`. CAPA adds these tags to the subnets it creates, but not to subnets that you bring yourself.

CAPA also tags the secondary subnets that hold the pod IP addresses as private subnets. An internal load balancer can therefore end up in a pod subnet. If it must be reachable from outside the VPC's primary CIDR, choose the subnets explicitly, for example with the `service.beta.kubernetes.io/aws-load-balancer-subnets` annotation or `loadBalancerSubnets` in a Gateway API `LoadBalancerConfiguration`.

## Deleting a cluster

CAPA does not delete load balancers when it deletes an EKS cluster. Delete all `Service`s of type `LoadBalancer`, `Ingress`es and `Gateway`s that this controller manages before you delete the cluster or the bundle. Otherwise their load balancers, target groups and security groups stay in the VPC and block its deletion.
