{
  "import.server" : { },
  "import.local" : { },
  "properties" : {
  {{- if .Values.graphdb.security.enabled }}
    "security.enabled" : true,
  {{- end }}
    "current.location" : ""
  }
}
