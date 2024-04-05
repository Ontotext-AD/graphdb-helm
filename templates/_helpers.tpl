{{/*
Renders the URL address at which GraphDB would be accessed
*/}}
{{- define "graphdb.url.public" -}}
  {{- printf "%s://%s%s" .Values.deployment.protocol .Values.deployment.host .Values.graphdb.workbench.subpath -}}
{{- end }}

{{/*
Combined image pull secrets
*/}}
{{- define "graphdb.combinedImagePullSecrets" -}}
  {{- $secrets := concat .Values.global.imagePullSecrets .Values.deployment.imagePullSecrets }}
  {{- tpl ( toYaml $secrets ) . -}}
{{- end -}}

{{/*
Renders the container image for GraphDB
*/}}
{{- define "graphdb.image" -}}
  {{- $repository := .Values.images.graphdb.repository -}}
  {{- $tag := .Values.images.graphdb.tag | default .Chart.AppVersion | toString -}}
  {{- $image := printf "%s:%s" $repository $tag -}}
  {{/* Add registry if present */}}
  {{- $registry := .Values.global.imageRegistry | default .Values.images.graphdb.registry -}}
  {{- if $registry -}}
    {{- $image = printf "%s/%s" $registry $image -}}
  {{- end -}}
  {{/* Add SHA if provided */}}
  {{- if .Values.images.graphdb.sha -}}
    {{- $image = printf "%s@sha256:%s" $image .Values.images.graphdb.sha -}}
  {{- end -}}
  {{- $image -}}
{{- end -}}

{{/*
Renders the gRPC address of each GraphDB node that is part of the cluster. Used in the cluster JSON config.
*/}}
{{- define "graphdb.cluster.nodes.json" -}}
  {{- range $i, $node_index := until (int .Values.graphdb.clusterConfig.nodesCount) -}}
    "{{ include "graphdb.fullname" $ }}-{{ $node_index }}.{{ include "graphdb.fullname.service.headless" $ }}.{{ $.Release.Namespace }}.svc.cluster.local:7300"
    {{- if gt (sub (int $.Values.graphdb.clusterConfig.nodesCount) 1 ) $node_index -}}
      {{- ", \n" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Renders the HTTP address of each GraphDB node that is part of the cluster, joined by a comma.
*/}}
{{- define "graphdb-proxy.cluster.nodes" -}}
  {{- range $i, $node_index := until (int $.Values.graphdb.clusterConfig.nodesCount) -}}
    http://{{ include "graphdb.fullname" $ }}-{{ $node_index }}.{{ include "graphdb.fullname.service.headless" $ }}.{{ $.Release.Namespace }}.svc.cluster.local:7200
    {{- if gt (sub (int $.Values.graphdb.clusterConfig.nodesCount) 1 ) $node_index -}}
      {{- ", " -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
