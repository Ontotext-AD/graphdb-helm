# Templated Extra Objects and Chart values Example

This example shows how to configure the extra chart values with templated items.

## Configuration

The default [values.yaml](values.yaml) in the example creates an additional configmap resource and
environment variables which reference sections from values.yaml. The additional configmap and environment variables are templated with Helm
and have use of `include`, `tpl`, `range` and `if`. Other templating functions are also supported.

NOTE: For templated resources in extraObjects, extraEnv, extraVolumes, etc., they need to be a string instead of YAML
object.

## Usage

```bash
helm upgrade --install --values ./values.yaml graphdb ontotext/graphdb
```
