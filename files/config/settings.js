{
  "import.server" : { },
  "import.local" : { },
  "properties" : {
  {{- if .Values.graphdb.security.enabled }}
    "security.enabled" : true,
  {{- end }}
    "current.location" : ""
  },
  "locations" : {
    "" : {
      "location" : "",
      "authType" : "none",
      "password" : null,
      "username" : null,
      "defaultRepository" : null
    }
  }
}
