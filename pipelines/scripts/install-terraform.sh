#!/usr/bin/env bash
set -euo pipefail

TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.16.1}"
ARCH="amd64"

case "$(uname -m)" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

archive="terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip"
base_url="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}"

curl --fail --location --silent --show-error "${base_url}/${archive}" --output "/tmp/${archive}"
curl --fail --location --silent --show-error "${base_url}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" --output /tmp/terraform_SHA256SUMS

expected="$(grep " ${archive}$" /tmp/terraform_SHA256SUMS | awk '{print $1}')"
actual="$(sha256sum "/tmp/${archive}" | awk '{print $1}')"
if [[ -z "${expected}" || "${actual}" != "${expected}" ]]; then
  echo "Terraform archive checksum verification failed." >&2
  exit 1
fi

mkdir -p /tmp/terraform-bin "${HOME}/.local/bin"
unzip -oq "/tmp/${archive}" -d /tmp/terraform-bin
install -m 0755 /tmp/terraform-bin/terraform "${HOME}/.local/bin/terraform"
echo "##vso[task.prependpath]${HOME}/.local/bin"
"${HOME}/.local/bin/terraform" version
