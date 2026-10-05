<!--
The upstream chart is consumed unmodified as a Helm dependency (alias `upstream`) of `helm/aws-load-balancer-controller`.
Bump it in that chart's `Chart.yaml`; put Giant Swarm specific resources in its `templates/` (extras) and wire new values through the bundle chart.
See the README for how values flow from the bundle chart to the workload chart.
-->

This PR..

### Checklist

- [ ] Updated `CHANGELOG.md`.
- [ ] Updated `values.schema.json` of the affected chart(s), if values changed.
