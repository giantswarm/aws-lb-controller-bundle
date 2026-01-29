# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Fix JSON Schema `values.schema.json` fields that were incorrectly defined as `"type": "null"` to allow actual configuration values (strings, integers, booleans, arrays, objects) in addition to null.

## [5.0.0] - 2026-01-29

### Changed

- Upgrade aws-load-balancer-controller from v2.8.3 to v3.0.0.
- Remove PSPs
- Move PolicyException to policy-exceptions namespace.
- Migrate from ClusterID to ClusterName
- Add additional permissions elasticloadbalancing:DescribeListenerAttributes

## [4.0.0] - 2026-01-20

### Changed

- Move Giant Swarm specific values to the bundle chart. Clean up the aws-load-balancer-controller chart from any GS specific stuff.
- Shorten bundle chart name to `aws-lb-controller-bundle`

## [3.0.0] - 2025-12-03

### Changed

- Merge both the bundle and app chart into the same repository. Now the AWS Load Balancer Controller app and the bundle containing the necessary IAM resources (managed by Crossplane) will live in this repository.
- The bundle chart now deploys the workload cluster chart using Flux HelmRelease instead of App CR.
- Make sure both the bundle and app charts have been pushed to the catalogs before pushing to the capa app collection

## [2.2.1] - 2025-10-30

### Changed

- Updated E2E tests to use apptest-framework v2.0.1
- Add unhealthyPodEvictionPolicy to PodDisruptionPolicy
- Declare status port on deployment

## [2.2.0] - 2025-04-22

### Removed

- Get rid of legacy in-house slo framework.

### Changed

- Set home URL in chart metadata.

## [2.1.0] - 2024-09-23

### Changed

- Update to upstream version 2.8.3.

## [2.0.0] - 2024-09-11

### Changed

- Change versioning system to our own app version.

## [1.6.1-gs.3] - 2024-09-11

### Changed

- Update Kyverno PolicyExceptions to v2 and fallback to v2beta1.

### Removed

- Remove dependabot configuration, as we want to use Renovate.

## [1.6.1-gs2.1] - 2024-08-01

## Fixed

- Add missing tag for ALB cleanup

## [1.6.1-gs2] - 2024-07-31

### Changed

- Add default tag to enable loadbalancer cleanup

## [1.6.1-gs.1] - 2024-05-30

## [1.6.1] - 2024-03-12

### Fixed

- Add `Ingress` network policy to make the app work in `kube-system` namespace.

## [1.6.0] - 2024-02-01

### Changed

- Bump upstream chart version to v2.6.1.

## [1.5.1] - 2024-02-01

### Fixed

- Use correct role name for CAPA provider.

## [1.5.0] - 2023-10-30

### Added

- Add PSS exceptions.

## [1.4.3] - 2023-10-12

## [1.4.2] - 2023-10-12

### Fixed

- Fix usage of PSP

## [1.4.1] - 2023-09-26

## [1.4.0] - 2023-09-14

### Changed

- Set minimum CPU to `50m` in the VPA.

## [1.3.4] - 2023-08-28

### Fixed

- PSP name

### Changed

- Migration from monitoring labels to ServiceMonitor.

### Added

- Added a new psp for CAPA support.

## [1.3.3] - 2023-07-13

### Added

- `Values.image.registry`

### Changed

- Template for image reference in deployment.yaml
- `application.giantswarm.io/team` annotation to Phoenix

## [1.3.2] - 2023-06-30

### Changed

- Add VPA

### Fixed

- Detect China region to fix IRSA role

## [1.3.1] - 2023-04-24

### Changed

- Metadata: use SVG icon.

## [1.3.0] - 2023-04-12

### Added

- Add IRSA annotation automatically based on Account ID and Cluster ID.

## [1.2.1] - 2023-01-31

### Changed

- Add helpers for setting values `region`, `vpcId` and IAM role annotations automatically from Giant Swarm provided default cluster values.

## [1.2.0] - 2022-04-12

### Changed

- Enable PodDisruptionBudget to prevent unavailability of the admission webhook during cluster maintenances.

## [1.1.0] - 2022-03-17

### Changed

- Synchronize with upstream helm chart version 1.4.1 containing AWS Load Balancer Controller [v2.4.1](https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/tag/v2.4.1)

## [1.0.3] - 2021-12-17

### Changed

- Change README link to absolute path to avoid problems when it is shown in Happa.

## [1.0.2] - 2021-12-14

### Added

- Adds annotation `giantswarm.io/monitoring-app-label` to metrics (status) service as a persistent identifier for monitoring

## [1.0.1] - 2021-12-02

- Metrics service
- Giant Swarm monitoring labels to deployment template

## [1.0.0] - 2021-11-19

### Added

- Implement network policy to allow egress traffic

### Updated
- values.yaml with resource limits/requests
- values.yaml validation schema

## [0.1.0] - 2021-11-19

### Added
- Upstream helm chart
- Automatic clusterName
- App description in README.md

[Unreleased]: https://github.com/giantswarm/aws-lb-controller-bundle/compare/v5.0.0...HEAD
[5.0.0]: https://github.com/giantswarm/aws-lb-controller-bundle/compare/v4.0.0...v5.0.0
[4.0.0]: https://github.com/giantswarm/aws-lb-controller-bundle/compare/v3.0.0...v4.0.0
[3.0.0]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v2.2.1...v3.0.0
[2.2.1]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v2.2.0...v2.2.1
[2.2.0]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.6.1-gs.3...v2.0.0
[1.6.1-gs.3]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.6.1-gs2.1...v1.6.1-gs.3
[1.6.1-gs2.1]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.6.1-gs2...v1.6.1-gs2.1
[1.6.1-gs2]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.6.1-gs.1...v1.6.1-gs2
[1.6.1-gs.1]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.6.1...v1.6.1-gs.1
[1.6.1]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.5.1...v1.6.0
[1.5.1]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.4.3...v1.5.0
[1.4.3]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.4.2...v1.4.3
[1.4.2]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.4.1...v1.4.2
[1.4.1]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.3.4...v1.4.0
[1.3.4]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.3.3...v1.3.4
[1.3.3]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.0.3...v1.1.0
[1.0.3]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/giantswarm/aws-load-balancer-controller-app/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/giantswarm/aws-load-balancer-controller-app/releases/tag/v0.1.0
