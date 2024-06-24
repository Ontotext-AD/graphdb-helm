# GraphDB with Custom Logback Configuration

GraphDB comes with a pre-configured Logback XML using sensible configuration defaults. 
However, for certain use cases, it might need to be fine-tuned. 

This example shows how to use a custom Logback XML configuration with GraphDB's Helm chart.

## Usage

1. Customize [configmap-logback.yaml](configmap-logback.yaml) according to your needs and apply:

   ```bash
   kubecttl apply -f configmap-logback.yaml
   ```

2. Configure the Helm chart to use the custom ConfigMap in [values.yaml](values.yaml)

   ```yaml
   configuration:
     logback:
       existingConfigmap: "graphdb-custom-logback-config"
   ```

3. Deploy the Helm chart with the custom configurations

   ```bash
   helm upgrade --install --values values.yaml graphdb-logback ../../
   ```
