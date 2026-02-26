{{/* vim: set filetype=mustache: */}}

{{/*
Fullname for GS extras — must produce the same name as the upstream sub-chart
so that VPA targets the right Deployment and NetworkPolicy selects the right pods.

IMPORTANT: These helpers use a unique "extras." prefix to avoid overriding
the upstream sub-chart's identically-named templates. Helm merges template
namespaces between parent and child charts, so naming collisions would cause
the sub-chart to use the parent's helpers instead of its own.
*/}}
{{- define "extras.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "aws-load-balancer-controller" .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Name for selector labels — matches upstream sub-chart's app.kubernetes.io/name
*/}}
{{- define "extras.name" -}}
{{- default "aws-load-balancer-controller" .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Chart label
*/}}
{{- define "extras.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels for GS extras resources
*/}}
{{- define "extras.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "extras.chart" . }}
{{ include "extras.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
application.giantswarm.io/team: {{ index .Chart.Annotations "application.giantswarm.io/team" | quote }}
{{- end -}}

{{/*
Selector labels — must match upstream sub-chart selector labels exactly.
*/}}
{{- define "extras.selectorLabels" -}}
app.kubernetes.io/name: {{ include "extras.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
