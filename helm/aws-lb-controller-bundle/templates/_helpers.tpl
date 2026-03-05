{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "aws-load-balancer-controller-bundle.name" -}}
{{- default .Chart.Name .Values.bundleNameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "aws-load-balancer-controller-bundle.fullname" -}}
{{- if .Values.fullBundleNameOverride -}}
{{- .Values.fullBundleNameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.bundleNameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aws-load-balancer-controller-bundle.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cluster-name" -}}
{{- if .Values.clusterName -}}
{{- .Values.clusterName -}}
{{- else -}}
{{- $name := .Release.Name -}}
{{- range $suffix := list (printf "-%s" .Chart.Name) "-alb-controller-bundle" "-aws-lbc-bundle" "-albc-bundle" -}}
{{- $name = trimSuffix $suffix $name -}}
{{- end -}}
{{- if eq $name .Release.Name -}}
{{- fail "Cannot find cluster name in the chart's release name prefix" -}}
{{- end -}}
{{- $name -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "aws-load-balancer-controller-bundle.labels" -}}
app.kubernetes.io/name: {{ include "aws-load-balancer-controller-bundle.name" . }}
helm.sh/chart: {{ include "aws-load-balancer-controller-bundle.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
giantswarm.io/service-type: "managed"
application.giantswarm.io/team: {{ index .Chart.Annotations "application.giantswarm.io/team" | quote }}
giantswarm.io/cluster: {{ include "cluster-name" . | quote }}
{{- end -}}

{{/*
Fetch crossplane config ConfigMap data
*/}}
{{- define "aws-load-balancer-controller-bundle.crossplaneConfigData" -}}
{{- $clusterName := (include "cluster-name" .) -}}
{{- $configmap := (lookup "v1" "ConfigMap" .Release.Namespace (printf "%s-crossplane-config" $clusterName)) -}}
{{- $cmvalues := dict -}}
{{- if and $configmap $configmap.data $configmap.data.values -}}
  {{- $cmvalues = fromYaml $configmap.data.values -}}
{{- else -}}
  {{- fail (printf "Crossplane config ConfigMap %s-crossplane-config not found in namespace %s or has no data" $clusterName .Release.Namespace) -}}
{{- end -}}
{{- $cmvalues | toYaml -}}
{{- end -}}

{{/*
Get trust policy statements for all provided OIDC domains
*/}}
{{- define "aws-load-balancer-controller-bundle.trustPolicyStatements" -}}
{{- $cmvalues := (include "aws-load-balancer-controller-bundle.crossplaneConfigData" .) | fromYaml -}}
{{- range $index, $oidcDomain := $cmvalues.oidcDomains -}}
{{- if not (eq $index 0) }}, {{ end }}{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:{{ $cmvalues.awsPartition }}:iam::{{ $cmvalues.accountID }}:oidc-provider/{{ $oidcDomain }}"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringLike": {
      "{{ $oidcDomain }}:sub": "system:serviceaccount:aws-load-balancer-controller:aws-load-balancer-controller"
    }
  }
}
{{- end -}}
{{- end -}}

{{/*
Set Giant Swarm specific values.
Mutates .Values in place before workloadValues reads them.
*/}}
{{- define "giantswarm.setValues" -}}
{{- $cmvalues := (include "aws-load-balancer-controller-bundle.crossplaneConfigData" .) | fromYaml -}}
{{- $clusterName := (include "cluster-name" .) -}}
{{- $_ := set .Values.serviceAccount.annotations "eks.amazonaws.com/role-arn" (printf "arn:%s:iam::%s:role/%s-aws-load-balancer-controller-role" $cmvalues.awsPartition $cmvalues.accountID $clusterName) -}}

{{- if not .Values.clusterName -}}
{{- $_ := set .Values "clusterName" $clusterName -}}
{{- end -}}

{{/*    We always need to pass the following tags so that resources created by this controller are removed by CAPA when removing a CAPA cluster */}}
{{/*    - "kubernetes.io/cluster/$clusterName=owned"*/}}
{{/*    - "kubernetes.io/service-name=aws-alb-controller"*/}}
{{- $_ := set .Values.defaultTags (printf "kubernetes.io/cluster/%s" $clusterName) "owned" }}
{{- $_ := set .Values.defaultTags "kubernetes.io/service-name" "aws-alb-controller" }}
{{- end -}}

{{/*
Combine image registry + name into a single repository string for the upstream chart.
GS uses image.registry + image.name; upstream uses image.repository.
*/}}
{{- define "giantswarm.combineImage" -}}
{{- printf "%s/%s" .registry .name -}}
{{- end -}}

{{/*
Build workload chart values from flat bundle values.
Strips bundle-only keys and restructures into:
  upstream:
    <all upstream controller values>
  verticalPodAutoscaler: ...
  global: ...
*/}}
{{- define "giantswarm.workloadValues" -}}
{{- $workload := dict -}}

{{/* Keys that are bundle-only and must NOT be forwarded to the workload chart */}}
{{- $bundleOnlyKeys := list "bundleNameOverride" "fullBundleNameOverride" "ociRepositoryUrl" -}}

{{/* Keys that are GS extras — forwarded at the top level of the workload chart */}}
{{- $extrasKeys := list "verticalPodAutoscaler" "global" "networkPolicy" -}}

{{/* Keys that need special transformation */}}
{{- $specialKeys := list "image" "clusterName" -}}

{{/* 1. Forward extras at top level */}}
{{- range $key := $extrasKeys -}}
{{-   if hasKey $.Values $key -}}
{{-     $_ := set $workload $key (index $.Values $key) -}}
{{-   end -}}
{{- end -}}

{{/* 2. Build upstream values dict from all remaining non-reserved keys */}}
{{- $upstream := dict -}}

{{/* CRITICAL: nameOverride preserves selector labels during upgrade */}}
{{- $_ := set $upstream "nameOverride" "aws-load-balancer-controller" -}}

{{/* Combine image.registry + image.name into image.repository for upstream */}}
{{- if .Values.image -}}
{{-   $img := dict -}}
{{-   if and .Values.image.registry .Values.image.name -}}
{{-     $_ := set $img "repository" (include "giantswarm.combineImage" .Values.image) -}}
{{-   end -}}
{{-   if .Values.image.tag -}}
{{-     $_ := set $img "tag" .Values.image.tag -}}
{{-   end -}}
{{-   if .Values.image.pullPolicy -}}
{{-     $_ := set $img "pullPolicy" .Values.image.pullPolicy -}}
{{-   end -}}
{{-   $_ := set $upstream "image" $img -}}
{{- end -}}

{{/* Copy clusterName into upstream block */}}
{{- if .Values.clusterName -}}
{{-   $_ := set $upstream "clusterName" .Values.clusterName -}}
{{- end -}}

{{/* Copy all other non-reserved keys into upstream */}}
{{- $reservedKeys := concat $bundleOnlyKeys $extrasKeys $specialKeys (list "nameOverride" "fullnameOverride") -}}
{{- range $key, $val := .Values -}}
{{-   if not (has $key $reservedKeys) -}}
{{-     $_ := set $upstream $key $val -}}
{{-   end -}}
{{- end -}}

{{- $_ := set $workload "upstream" $upstream -}}
{{- $workload | toYaml -}}
{{- end -}}
