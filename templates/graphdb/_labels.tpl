{{/*
Helper functions for labels related to GraphDB resources
*/}}

{{- define "graphdb.fullname.configmap.environment" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "environment" -}}
{{- end -}}

{{- define "graphdb.fullname.configmap.properties" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "properties" -}}
{{- end -}}

{{- define "graphdb.fullname.secret.properties" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "properties" -}}
{{- end -}}

{{- define "graphdb.fullname.configmap.initial-settings" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "initial-settings" -}}
{{- end -}}

{{- define "graphdb.fullname.secret.initial-users" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "initial-users" -}}
{{- end -}}

{{- define "graphdb.fullname.service.headless" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "headless" -}}
{{- end -}}
