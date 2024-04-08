{{/*
Expand the name of the chart.
*/}}
{{- define "graphdb.name" -}}
  {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "graphdb.fullname" -}}
  {{- if .Values.fullnameOverride }}
    {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
  {{- else }}
    {{- $name := default .Chart.Name .Values.nameOverride }}
    {{- if contains $name .Release.Name }}
      {{- .Release.Name | trunc 63 | trimSuffix "-" }}
    {{- else }}
      {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "graphdb.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "graphdb.labels" -}}
helm.sh/chart: {{ include "graphdb.chart" . }}
{{ include "graphdb.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: graphdb
app.kubernetes.io/part-of: graphdb
{{- if .Values.labels }}
{{ tpl ( toYaml .Values.labels ) $ }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "graphdb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "graphdb.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "graphdb.serviceAccountName" -}}
  {{- if .Values.graphdb.serviceAccount.create }}
    {{- default (include "graphdb.fullname" .) .Values.graphdb.serviceAccount.name }}
  {{- else }}
    {{- default "default" .Values.graphdb.serviceAccount.name }}
  {{- end }}
{{- end }}
