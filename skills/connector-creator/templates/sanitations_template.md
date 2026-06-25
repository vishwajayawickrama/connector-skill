# Sanitation for OpenAPI specification

This document records the sanitation done on top of the official OpenAPI specification from <SPEC_SOURCE_URL>.

_Created_: <YYYY/MM/DD> \
_Updated_: <YYYY/MM/DD> \

<!-- Numbered sections below. Auto-detected sections are marked <!-- auto-generated -->.
     Human-authored sections are preserved across regenerations.
     When regenerating, replace auto-generated sections with fresh detection
     but always preserve human-authored ones. -->

1. Change the `url` property of the servers object
- **Original**: `https://graph.microsoft.com/v1.0`
- **Updated**: `https://graph.microsoft.com`
- **Reason**: Common prefix added to base URL to simplify endpoint paths.
<!-- auto-generated -->

2. Update the API Paths
- **Original**: Paths included common prefix `/v1.0` in each endpoint.
- **Updated**: Common prefix removed from endpoints as it is now in the base URL.
- **Reason**: Simplifies API paths and avoids duplication.
<!-- auto-generated -->

3. Update `date-time` to `datetime`
- **Original**: `"format":"date-time"`
- **Updated**: `"format":"datetime"`
- **Reason**: The `date-time` format is not compatible with the openAPI generation tool. Updated to `datetime` for Ballerina compatibility.
<!-- auto-generated -->

## OpenAPI cli command

The following command was used to generate the Ballerina client from the OpenAPI specification.
The command should be executed from the repository root directory.

```bash
bal openapi -i docs/spec/openapi.json -o ballerina --mode client --client-methods remote --license docs/license.txt
```

Note: The license year is hardcoded to 2025, change if necessary.
