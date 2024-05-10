{{/*
Creates another chart name for the proxy service to distinguish it from GraphDB.
*/}}
{{- define "graphdb-proxy.chartName" -}}
{{- printf "%s-proxy" .Chart.Name -}}
{{- end }}

{{/*
Expand the name of the proxy service.
*/}}
{{- define "graphdb-proxy.name" -}}
{{- default (include "graphdb-proxy.chartName" .) .Values.proxy.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name for the proxy service.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "graphdb-proxy.fullname" -}}
{{- if .Values.proxy.fullnameOverride }}
{{- .Values.proxy.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default (include "graphdb-proxy.chartName" .) .Values.proxy.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels for the proxy service.
*/}}
{{- define "graphdb-proxy.labels" -}}
helm.sh/chart: {{ include "graphdb.chart" . }}
{{ include "graphdb-proxy.selectorLabels" . }}
app.kubernetes.io/version: {{ coalesce .Values.image.tag .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: graphdb-proxy
app.kubernetes.io/part-of: graphdb
{{- if .Values.labels }}
{{ tpl (toYaml .Values.labels) . }}
{{- end }}
{{- if .Values.proxy.labels }}
{{ tpl (toYaml .Values.proxy.labels) . }}
{{- end }}
{{- end }}

{{/*
Selector labels for the proxy service.
*/}}
{{- define "graphdb-proxy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "graphdb-proxy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "graphdb-proxy.fullname.configmap.properties" -}}
  {{- printf "%s-%s" (include "graphdb-proxy.fullname" .) "properties" -}}
{{- end -}}

{{- define "graphdb-proxy.fullname.secret.properties" -}}
  {{- printf "%s-%s" (include "graphdb-proxy.fullname" .) "properties" -}}
{{- end -}}

{{- define "graphdb-proxy.fullname.service.headless" -}}
  {{- printf "%s-%s" (include "graphdb-proxy.fullname" .) "headless" -}}
{{- end -}}
