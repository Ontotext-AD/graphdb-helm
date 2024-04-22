{{/*
Combined image pull secrets
*/}}
{{- define "graphdb.combinedImagePullSecrets" -}}
  {{- $secrets := concat .Values.global.imagePullSecrets .Values.image.pullSecrets }}
  {{- tpl ( toYaml $secrets ) . -}}
{{- end -}}

{{/*
Renders the container image for GraphDB
*/}}
{{- define "graphdb.image" -}}
  {{- $repository := .Values.image.repository -}}
  {{- $tag := .Values.image.tag | default .Chart.AppVersion | toString -}}
  {{- $image := printf "%s:%s" $repository $tag -}}
  {{/* Add registry if present */}}
  {{- $registry := .Values.global.imageRegistry | default .Values.image.registry -}}
  {{- if $registry -}}
    {{- $image = printf "%s/%s" $registry $image -}}
  {{- end -}}
  {{/* Add SHA if provided */}}
  {{- if .Values.image.sha -}}
    {{- $image = printf "%s@sha256:%s" $image .Values.image.sha -}}
  {{- end -}}
  {{- $image -}}
{{- end -}}

{{/*
Renders the gRPC address of each GraphDB node that is part of the cluster as a JSON array. Used in the cluster JSON config.
*/}}
{{- define "graphdb.cluster.nodes.json" -}}
  {{- $pod_name := include "graphdb.fullname" . -}}
  {{- $service_name := include "graphdb.fullname.service.headless" . -}}
  {{- $namespace := include "graphdb.namespace" . -}}
  {{- $cluster_domain := .Values.global.clusterDomain -}}
  {{- $service_rpc_port := .Values.headlessService.ports.rpc -}}
  {{- $nodes := list -}}
  {{- range $i, $node_index := until (int .Values.replicas) -}}
    {{- $nodes = append $nodes (printf "%s-%s.%s.%s.svc.%s:%s" $pod_name (toString $node_index) $service_name $namespace $cluster_domain (toString $service_rpc_port)) -}}
  {{- end -}}
  {{- toPrettyJson $nodes -}}
{{- end -}}

{{/*
Renders the HTTP address of each GraphDB node that is part of the cluster, joined by a comma.
*/}}
{{- define "graphdb-proxy.cluster.nodes" -}}
  {{- $pod_name := include "graphdb.fullname" . -}}
  {{- $service_name := include "graphdb.fullname.service.headless" . -}}
  {{- $namespace := include "graphdb.namespace" . -}}
  {{- $cluster_domain := .Values.global.clusterDomain -}}
  {{- $service_http_port := .Values.headlessService.ports.http -}}
  {{- range $i, $node_index := until (int .Values.replicas) -}}
    http://{{ $pod_name }}-{{ $node_index }}.{{ $service_name }}.{{ $namespace }}.svc.{{ $cluster_domain }}:{{ $service_http_port }}
    {{- if gt (sub (int $.Values.replicas) 1 ) $node_index -}}
      {{- ", " -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
