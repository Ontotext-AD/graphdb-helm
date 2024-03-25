{
  "import.server" : { },
  "import.local" : { },
  "properties" : {
  {{- if .Values.security.enabled }}
    "security.enabled" : true,
  {{- end }}
    "current.location" : ""
  }
}
