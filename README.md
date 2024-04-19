# graphdb

![Version: 10.6.3](https://img.shields.io/badge/Version-10.6.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 10.6.3](https://img.shields.io/badge/AppVersion-10.6.3-informational?style=flat-square)

GraphDB is an enterprise ready Semantic Graph Database

**Homepage:** <https://graphdb.ontotext.com/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Ontotext GraphDB team | <graphdb-support@ontotext.com> |  |

## Source Code

* <https://github.com/Ontotext-AD/graphdb-helm>

## Requirements

Kubernetes: `^1.22.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| deployment.host | string | `"localhost"` |  |
| deployment.imagePullPolicy | string | `"IfNotPresent"` | Defines the policy with which components will request their image. |
| deployment.ingress | object | `{"annotations":{},"class":"nginx","enabled":true,"maxRequestSize":"512M","timeout":{"connect":5,"read":600,"send":600}}` | Ingress related configurations |
| deployment.ingress.annotations | object | `{}` | Sets extra ingress annotations |
| deployment.ingress.maxRequestSize | string | `"512M"` | Sets the maximum size for all requests to the underlying Nginx |
| deployment.ingress.timeout | object | `{"connect":5,"read":600,"send":600}` | Default timeouts in seconds for the underlying Nginx. |
| deployment.protocol | string | `"http"` | The hostname and protocol at which the graphdb will be accessible. Needed to configure ingress as well as some components require it to properly render their UIs |
| deployment.tls.enabled | bool | `false` | Feature toggle for SSL termination. Disabled by default. If TLS is enabled, the protocol should also be updated (https) |
| deployment.tls.secretName | string | `nil` | Name of a Kubernetes secret object with the key and certificate. If TLS is enabled, it's required to be provided, depending on the deployment. |
| extraLabels | object | `{}` |  |
| global.imagePullSecrets | list | `[]` |  |
| global.imageRegistry | string | `"docker.io"` |  |
| global.storageClass | string | `"standard"` |  |
| graphdb.clusterConfig.clusterCreationTimeout | int | `60` | Timeout for the cluster creation CURL query. Note: By default helm waits for Kubernetes commands to complete for 5 minutes. You can increase that by adding "--timeout 10m" to the helm command. |
| graphdb.clusterConfig.clusterSecret | string | `"s3cr37"` | A secret used for secure communication amongst the nodes in the cluster. |
| graphdb.clusterConfig.electionMinTimeout | int | `8000` | Cluster configuration parameters: Refer to https://graphdb.ontotext.com/documentation/10.6/creating-a-cluster.html#creation-parameters The minimum wait time in milliseconds for a heartbeat from a leader. |
| graphdb.clusterConfig.electionRangeTimeout | int | `6000` |  |
| graphdb.clusterConfig.existingClusterConfig | string | `nil` | Use a custom JSON configuration when creating the cluster, see https://graphdb.ontotext.com/documentation/10.6/creating-a-cluster.html#creation-parameters The resources expect a configmap containing a key "cluster-config.json" with the JSON for cluster creation |
| graphdb.clusterConfig.heartbeatInterval | int | `2000` |  |
| graphdb.clusterConfig.messageSize | int | `64` |  |
| graphdb.clusterConfig.nodesCount | int | `1` | Number of GraphDB nodes to be used in the cluster. Set value to 1 to run a standalone GraphDB instance. |
| graphdb.clusterConfig.transactionLogMaximumSizeGB | int | `50` |  |
| graphdb.clusterConfig.verificationTimeout | int | `1500` |  |
| graphdb.clusterProxy | object | `{"affinity":{},"extraEnv":[],"extraEnvFrom":[],"extraInitContainers":[],"extraVolumeMounts":[],"extraVolumes":[],"headlessService":{"annotations":{}},"java_args":"-XX:MaxRAMPercentage=70 -Ddefault.min.distinct.threshold=100m -XX:+UseContainerSupport","livenessProbe":{"httpGet":{"path":"/proxy/health","port":"gdb-proxy-port"},"initialDelaySeconds":120,"periodSeconds":10,"timeoutSeconds":5},"nodeSelector":{},"persistence":{"enablePersistence":true,"volumeClaimTemplateSpec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"500Mi"}}}},"podAnnotations":{},"podLabels":{},"podSecurityContext":{},"readinessProbe":{"httpGet":{"path":"/proxy/ready","port":"gdb-proxy-port"},"periodSeconds":10,"timeoutSeconds":5},"replicas":1,"resources":{"limits":{"memory":"1500Mi"},"requests":{"cpu":"100m","memory":"1500Mi"}},"revisionHistoryLimit":10,"securityContext":{},"service":{"annotations":{}},"serviceType":"LoadBalancer","startupProbe":{"failureThreshold":60,"httpGet":{"path":"/proxy/ready","port":"gdb-proxy-port"},"periodSeconds":5,"timeoutSeconds":3},"terminationGracePeriodSeconds":30,"tolerations":[],"topologySpreadConstraints":[]}` | Settings for the GraphDB cluster proxy used to communicate with the GraphDB cluster Note: If there is no cluster (graphdb.clusterConfig.nodesCount is set to 1) no proxy will be deployed |
| graphdb.clusterProxy.headlessService | object | `{"annotations":{}}` | GraphDB cluster proxy headless service configurations |
| graphdb.clusterProxy.java_args | string | `"-XX:MaxRAMPercentage=70 -Ddefault.min.distinct.threshold=100m -XX:+UseContainerSupport"` | Java arguments with which the cluster proxy instances will be launched. GraphDB configuration properties can also be passed here in the format -Dprop=value |
| graphdb.clusterProxy.livenessProbe | object | `{"httpGet":{"path":"/proxy/health","port":"gdb-proxy-port"},"initialDelaySeconds":120,"periodSeconds":10,"timeoutSeconds":5}` | Configurations for the GraphDB cluster proxy liveness probe. Misconfigured probe can lead to a failing cluster. |
| graphdb.clusterProxy.persistence | object | `{"enablePersistence":true,"volumeClaimTemplateSpec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"500Mi"}}}}` | Persistence configurations. By default, Helm will use a PV that reads and writes to the host file system. |
| graphdb.clusterProxy.readinessProbe | object | `{"httpGet":{"path":"/proxy/ready","port":"gdb-proxy-port"},"periodSeconds":10,"timeoutSeconds":5}` | Configurations for the GraphDB cluster proxy readiness probe. Misconfigured probe can lead to a failing cluster. |
| graphdb.clusterProxy.replicas | int | `1` | Number of cluster proxies used to access the GraphDB cluster |
| graphdb.clusterProxy.resources | object | `{"limits":{"memory":"1500Mi"},"requests":{"cpu":"100m","memory":"1500Mi"}}` | Minimum requirements for a successfully running GraphDB cluster proxy |
| graphdb.clusterProxy.service | object | `{"annotations":{}}` | GraphDB cluster proxy service configurations |
| graphdb.clusterProxy.serviceType | string | `"LoadBalancer"` | Service type used by the graphdb-cluster-proxy service Note: If using ALB in AWS EKS this will default to being on the public internet |
| graphdb.clusterProxy.startupProbe | object | `{"failureThreshold":60,"httpGet":{"path":"/proxy/ready","port":"gdb-proxy-port"},"periodSeconds":5,"timeoutSeconds":3}` | Configurations for the GraphDB cluster proxy startup probe. Misconfigured probe can lead to a failing cluster. |
| graphdb.configs | string | `nil` | References to configuration maps containing settings.js, users.js, graphdb.properties, and logback.xml files to overwrite the default GraphDB configuration. For reference see https://graphdb.ontotext.com/documentation/10.6/directories-and-config-properties.html |
| graphdb.import_directory_mount.enabled | bool | `false` |  |
| graphdb.import_directory_mount.volumeClaimTemplateSpec.accessModes[0] | string | `"ReadWriteOnce"` |  |
| graphdb.import_directory_mount.volumeClaimTemplateSpec.resources.requests.storage | string | `"10Gi"` |  |
| graphdb.jobPodSecurityContext | object | `{}` |  |
| graphdb.jobResources | object | `{}` |  |
| graphdb.jobSecurityContext | object | `{}` |  |
| graphdb.node | object | `{"affinity":{},"args":null,"command":null,"extraEnv":[],"extraEnvFrom":[],"extraInitContainers":[],"extraVolumeMounts":[],"extraVolumes":[],"initContainerResources":{},"initContainerSecurityContext":{},"java_args":"-XX:MaxRAMPercentage=70 -Ddefault.min.distinct.threshold=100m -XX:+UseContainerSupport","license":null,"licenseFilename":"graphdb.license","livenessProbe":{"httpGet":{"path":"/protocol","port":"graphdb"},"initialDelaySeconds":60,"periodSeconds":10,"timeoutSeconds":5},"nodeSelector":{},"persistence":{"volumeClaimTemplateSpec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}}}},"podAnnotations":{},"podLabels":{},"podSecurityContext":{},"readinessProbe":{"httpGet":{"path":"/protocol","port":"graphdb"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"resources":{"limits":{"memory":"2Gi"},"requests":{"cpu":0.5,"memory":"2Gi"}},"revisionHistoryLimit":10,"securityContext":{},"service":{"annotations":{}},"startupProbe":{"failureThreshold":30,"httpGet":{"path":"/protocol","port":"graphdb"},"periodSeconds":10,"timeoutSeconds":5},"terminationGracePeriodSeconds":120,"tolerations":[],"topologySpreadConstraints":[]}` | Settings for the GraphDB cluster nodes |
| graphdb.node.java_args | string | `"-XX:MaxRAMPercentage=70 -Ddefault.min.distinct.threshold=100m -XX:+UseContainerSupport"` | Java arguments with which node instances will be launched. GraphDB configuration properties can also be passed here in the format -Dprop=value |
| graphdb.node.license | string | `nil` | Reference to a secret containing 'graphdb.license' file to be used by the nodes. Important: Must be created beforehand |
| graphdb.node.licenseFilename | string | `"graphdb.license"` | File name of the GraphDB license file in the existing license secret. Default is graphdb.license |
| graphdb.node.livenessProbe | object | `{"httpGet":{"path":"/protocol","port":"graphdb"},"initialDelaySeconds":60,"periodSeconds":10,"timeoutSeconds":5}` | Configurations for the GraphDB node liveness probe. Misconfigured probe can lead to a failing cluster. |
| graphdb.node.persistence | object | `{"volumeClaimTemplateSpec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"5Gi"}}}}` | Persistence configurations. By default, Helm will use a PV that reads and writes to the host file system. |
| graphdb.node.readinessProbe | object | `{"httpGet":{"path":"/protocol","port":"graphdb"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5}` | Configurations for the GraphDB node readiness probe. Misconfigured probe can lead to a failing cluster. |
| graphdb.node.resources | object | `{"limits":{"memory":"2Gi"},"requests":{"cpu":0.5,"memory":"2Gi"}}` | Below are minimum requirements for data sets of up to 50 million RDF triples For resizing, refer according to the GraphDB documentation https://graphdb.ontotext.com/documentation/10.6/requirements.html |
| graphdb.node.service | object | `{"annotations":{}}` | GraphDB node service configurations |
| graphdb.node.startupProbe | object | `{"failureThreshold":30,"httpGet":{"path":"/protocol","port":"graphdb"},"periodSeconds":10,"timeoutSeconds":5}` | Configurations for the GraphDB node startup probe. Misconfigured probe can lead to a failing cluster. |
| graphdb.pdb.create | bool | `false` |  |
| graphdb.pdb.maxUnavailable | string | `nil` |  |
| graphdb.pdb.minAvailable | string | `"51%"` |  |
| graphdb.security.enabled | bool | `false` |  |
| graphdb.security.provisioningPassword | string | `"iHaveSuperpowers"` |  |
| graphdb.security.provisioningUsername | string | `"provisioner"` |  |
| graphdb.workbench.subpath | string | `"/graphdb"` | This is the sub path at which GraphDB workbench can be opened. Should be configured in the API gateway (or any other proxy in front) |
| images.busybox.repository | string | `"busybox"` |  |
| images.busybox.tag | string | `"1.36.1"` |  |
| images.graphdb.registry | string | `"docker.io"` |  |
| images.graphdb.repository | string | `"ontotext/graphdb"` |  |
| images.graphdb.tag | string | `""` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)
