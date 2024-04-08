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
Renders the gRPC address of each GraphDB node that is part of the cluster as a JSON array. Used in the cluster JSON config.
*/}}
{{- define "graphdb.cluster.nodes.json" -}}
  {{- $pod_name := include "graphdb.fullname" . -}}
  {{- $service_name := include "graphdb.fullname.service.headless" . -}}
  {{- $service_rpc_port := .Values.graphdb.node.headlessService.ports.rpc -}}
  {{- $nodes := list -}}
  {{- range $i, $node_index := until (int .Values.graphdb.clusterConfig.nodesCount) -}}
    {{- $nodes = append $nodes (printf "%s-%s.%s.%s.svc.cluster.local:%s" $pod_name (toString $node_index) $service_name $.Release.Namespace (toString $service_rpc_port)) -}}
  {{- end -}}
  {{- toPrettyJson $nodes -}}
{{- end -}}

{{/*
Renders the HTTP address of each GraphDB node that is part of the cluster, joined by a comma.
*/}}
{{- define "graphdb-proxy.cluster.nodes" -}}
  {{- $pod_name := include "graphdb.fullname" . -}}
  {{- $service_name := include "graphdb.fullname.service.headless" . -}}
  {{- $service_http_port := .Values.graphdb.node.headlessService.ports.http -}}
  {{- range $i, $node_index := until (int $.Values.graphdb.clusterConfig.nodesCount) -}}
    http://{{ $pod_name }}-{{ $node_index }}.{{ $service_name }}.{{ $.Release.Namespace }}.svc.cluster.local:{{ $service_http_port }}
    {{- if gt (sub (int $.Values.graphdb.clusterConfig.nodesCount) 1 ) $node_index -}}
      {{- ", " -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
