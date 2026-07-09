{{/*
Helper functions for labels related to GraphDB Gateway API resources.
*/}}

{{- define "graphdb.fullname.httproute.https-redirect" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "https-redirect" -}}
{{- end -}}
