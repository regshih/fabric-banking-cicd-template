# Security policy

## Reporting a vulnerability

Use GitHub private vulnerability reporting for suspected vulnerabilities. Do not open a public issue containing credentials, tenant information, exploitable details, customer data, or unsanitized logs.

Include the affected path/version, impact, reproduction steps, and a proposed mitigation when possible. You should receive an acknowledgement within seven days. Disclosure timing will be coordinated after triage and remediation.

If a credential may have been exposed, revoke or rotate it immediately and follow the owning organization's incident-response process before attempting repository-history cleanup.

## Supported versions

Security fixes are applied to the current `main` branch. Consumers should create their own tested release tags and dependency-update process after generating a repository from this template.

## Contributor requirements

- Run repository validation and secret scanning.
- Use workload identity federation instead of reusable client secrets where supported.
- Preserve workspace separation and production approval gates.
- Never add real banking identifiers, customer data, completed deployment inventories, Terraform state, or unsanitized output.
- Treat unexpected Fabric or deployment errors as fatal; do not broaden the documented conflict fallback.
