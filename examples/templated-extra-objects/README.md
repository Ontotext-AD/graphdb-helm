# Templated Extra Objects Example

This example shows how to configure the extraObjects array with templated items

## Configuration

The default [values.yaml](values.yaml) in the example creates an additional configmap resource, which
references a section from values.yaml. The additional configmap is templated with Helm and has use
of `include` `tpl`, `range` and `if`. Other templating functions are also supported.

NOTE: For templated resource in extraObjects, it needs to be a string instead of YAML object

## Usage

```bash
helm upgrade --install --values ./values.yaml graphdb ontotext/graphdb
```
