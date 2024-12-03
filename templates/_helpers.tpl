{{/*
Combined image pull secrets
*/}}
{{- define "graphdb.combinedImagePullSecrets" -}}
  {{- $secrets := concat .Values.global.imagePullSecrets .Values.image.pullSecrets }}
  {{- tpl (toYaml $secrets) . -}}
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
  {{/* Add SHA digest if provided */}}
  {{- if .Values.image.digest -}}
    {{- $image = printf "%s@%s" $image .Values.image.digest -}}
  {{- end -}}
  {{- $image -}}
{{- end -}}

{{/*
Renders the external URL for GraphDB.
*/}}
{{- define "graphdb.external-url" -}}
{{- tpl .Values.configuration.externalUrl . -}}
{{- end -}}

{{/*
Render the protocol of the Tomcat connector.
*/}}
{{- define "graphdb.tomcat.protocol" -}}
{{- ternary "http" "https" (eq (.Values.configuration.tls.keystore.existingSecret | default "" | trim) "") -}}
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
  {{- $protocol := include "graphdb.tomcat.protocol" . }}
  {{- range $i, $node_index := until (int .Values.replicas) -}}
    {{ $protocol }}://{{ $pod_name }}-{{ $node_index }}.{{ $service_name }}.{{ $namespace }}.svc.{{ $cluster_domain }}:{{ $service_http_port }}
    {{- if gt (sub (int $.Values.replicas) 1) $node_index -}}
      {{- ", " -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Checks for potential issues and prints warning messages.
*/}}
{{- define "graphdb.notes.warnings" -}}
  {{- $warnings := list -}}
  {{- if and (gt (int .Values.replicas) 1) (not .Values.license.existingSecret) -}}
    {{- $warnings = append $warnings "WARNING: You are attempting to make a cluster without providing a secret for GraphDB Enterprise Edition license!" -}}
  {{- end -}}
  {{- if not .Values.persistence.enabled -}}
    {{- $warnings = append $warnings "WARNING: Persistence is disabled! You will lose your data when GraphDB pods are restarted or terminated!" -}}
  {{- end -}}
  {{- if and (gt (int .Values.replicas) 1) (eq (mod (int .Values.replicas) 2) 0) -}}
    {{- $warnings = append $warnings "WARNING: You are deploying a GraphDB cluster with an even amount of replicas! You should be using an odd amount of replicas." -}}
  {{- end -}}
  {{- if gt (len $warnings) 0 }}
    {{- print "\n" }}
    {{- range $warning, $index := $warnings }}
{{ print $index }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Converts custom users YAML to a pretty JSON for insertion in users.js
*/}}
{{- define "grahdb.security.extra-users.json" -}}
{{- if .Values.security.initialUsers.users -}}
  {{- range $user, $data := .Values.security.initialUsers.users -}}
    {{- $user | quote }}: {{ $data | mustToPrettyJson }},
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Calculate provisoner's bcrypt-hashed password
*/}}
{{- define "graphdb.security.provisioner.passwordHash" -}}
  {{- printf "%s" ( htpasswd .Values.security.provisioner.username .Values.security.provisioner.password | trimPrefix (printf "%s:" .Values.security.provisioner.username)) -}}
{{- end -}}
