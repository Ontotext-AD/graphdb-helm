{
  "users" : {
    "admin" : {
      "username" : "admin",
      "password" : "{bcrypt}$2a$10$H7uekkF1ZFLIV5M1g9tDs.syZGtkMqrfj2Si2SHG1WgwhpNqpZwne",
      "grantedAuthorities" : [ "ROLE_ADMIN" ],
      "appSettings" : {
        "DEFAULT_INFERENCE" : true,
        "DEFAULT_VIS_GRAPH_SCHEMA" : true,
        "DEFAULT_SAMEAS" : true,
        "IGNORE_SHARED_QUERIES" : false,
        "EXECUTE_COUNT" : true
      },
      "dateCreated" : 1618403171751
    },
    "provisioner" : {
      "username" : "{{ .Values.graphdb.security.provisioningUsername }}",
          "password" : "{bcrypt}{{ htpasswd .Values.graphdb.security.provisioningUsername .Values.graphdb.security.provisioningPassword | trimPrefix (printf "%s:" .Values.graphdb.security.provisioningUsername) }}",
          "grantedAuthorities" : [ "ROLE_ADMIN" ],
          "appSettings" : {
        "DEFAULT_INFERENCE" : true,
            "DEFAULT_VIS_GRAPH_SCHEMA" : true,
            "DEFAULT_SAMEAS" : true,
            "IGNORE_SHARED_QUERIES" : false,
            "EXECUTE_COUNT" : true
      },
      "dateCreated" : 1618403171751
    }
  },
  "import.server" : { },
  "import.local" : { },
  "properties" : {
  {{- if .Values.graphdb.security.enabled }}
    "security.enabled" : true,
  {{- end }}
    "current.location" : ""
  },
  "user_queries" : {
    "admin" : {
      "SPARQL Select template" : {
        "name" : "SPARQL Select template",
        "body" : "SELECT ?s ?p ?o\nWHERE {\n\t?s ?p ?o .\n} LIMIT 100",
        "shared" : false
      },
      "Clear graph" : {
        "name" : "Clear graph",
        "body" : "CLEAR GRAPH <http://example>",
        "shared" : false
      },
      "Add statements" : {
        "name" : "Add statements",
        "body" : "PREFIX dc: <http://purl.org/dc/elements/1.1/>\nINSERT DATA\n      {\n      GRAPH <http://example> {\n          <http://example/book1> dc:title \"A new book\" ;\n                                 dc:creator \"A.N.Other\" .\n          }\n      }",
        "shared" : false
      },
      "Remove statements" : {
        "name" : "Remove statements",
        "body" : "PREFIX dc: <http://purl.org/dc/elements/1.1/>\nDELETE DATA\n{\nGRAPH <http://example> {\n    <http://example/book1> dc:title \"A new book\" ;\n                           dc:creator \"A.N.Other\" .\n    }\n}",
        "shared" : false
      }
    }
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
