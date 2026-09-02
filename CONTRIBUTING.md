# Contributing

Thank you for helping improve this Microsoft Fabric CI/CD reference implementation.

## Before opening a change

1. Open an issue for substantial design changes.
2. Create a focused branch from `main` in your fork.
3. Keep the demonstration synthetic and vendor-neutral where possible.
4. Never include credentials, tenant-specific identifiers, customer data, Terraform state/plans, completed deployment inventories, or unsanitized logs.
5. Preserve least privilege, Dev/Prod separation, manual production approval, and fatal handling for unexpected deployment errors.

## Validate locally

Run:

```bash
python -m pip install --requirement requirements.txt --requirement requirements-dev.txt
python tests/validate_repo.py
python tests/validate_public_repo.py
terraform fmt -check -recursive terraform

terraform -chdir=terraform/bootstrap init -backend=false
terraform -chdir=terraform/bootstrap validate
terraform -chdir=terraform/environments/dev init -backend=false
terraform -chdir=terraform/environments/dev validate
terraform -chdir=terraform/environments/prod init -backend=false
terraform -chdir=terraform/environments/prod validate

checkov --directory terraform --framework terraform --compact
```

The pull request workflow repeats these checks and scans tracked files for likely secrets.

## Pull requests

- Explain the problem, solution, security impact, and validation performed.
- Update documentation and examples with behavioral changes.
- Do not weaken pinned dependency ranges or GitHub Action commit pins without review.
- Call out billable resources, destructive behavior, new privileges, or new recurring schedules.
- Keep commits reviewable; maintainers may squash when merging.

## Fabric artifacts

Keep `.platform` logical IDs stable and unique. Use placeholders plus `fabric-items/parameter.yml` for workspace-specific IDs and endpoints. Do not commit Lakehouse data or exported customer records.

By participating, you agree to follow [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
