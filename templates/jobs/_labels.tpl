{{/*
Helper functions for labels related to Job and provisioning resources
*/}}

{{- define "graphdb.fullname.configmap.cluster" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "cluster" -}}
{{- end -}}

{{- define "graphdb.fullname.configmap.utils" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "utils" -}}
{{- end -}}

{{- define "graphdb.fullname.secret.provisioning-user" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "provisioning-user" -}}
{{- end -}}

{{- define "graphdb.fullname.secret.backup-options" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "backup-options" -}}
{{- end -}}

{{- define "graphdb.fullname.job.create-cluster" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "create-cluster" -}}
{{- end -}}

{{- define "graphdb.fullname.job.patch-cluster" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "patch-cluster" -}}
{{- end -}}

{{- define "graphdb.fullname.job.provision-repositories" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "provision-repositories" -}}
{{- end -}}

{{- define "graphdb.fullname.job.provision-indices" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "provision-indices" -}}
{{- end -}}

{{- define "graphdb.fullname.job.scale-down-cluster" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "scale-down-cluster" -}}
{{- end -}}

{{- define "graphdb.fullname.job.scale-up-cluster" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "scale-up-cluster" -}}
{{- end -}}

{{- define "graphdb.fullname.cronjob.backup" -}}
  {{- printf "%s-%s" (include "graphdb.fullname" .) "backup" -}}
{{- end -}}
