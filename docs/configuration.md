# Configuration

The `niskala.yaml` file controls the generation process.

## Example Configuration

```yaml
odataEnvironments:
    - name: "Development"
      baseUrl: "https://ifsdev.example.com/"
      realms: "ifsrealm"
      clientId: "IFS_connect"
      clientSecret: "env:IFS_SECRET" # Uses String.fromEnvironment

niskala_service_gen:
    resource_path: ./metadata
    output: lib

apiDefinitions:
    - projection: "PurchaseRequisitionHandling.svc"
      method: "POST"
      endpoint: "/PurchaseRequisitionSet"
```

## Options

- `resource_path`: Path to your OpenAPI/OData JSON files.
- `output`: Root directory for generated code.
- `apiDefinitions`: List of endpoints to generate.
