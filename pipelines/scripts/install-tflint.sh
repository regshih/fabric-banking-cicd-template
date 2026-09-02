#!/usr/bin/env bash
set -euo pipefail

version="${TFLINT_VERSION:-0.64.0}"
archive="tflint_linux_amd64.zip"
base_url="https://github.com/terraform-linters/tflint/releases/download/v${version}"
install_dir="${HOME}/.local/bin"
temp_dir="$(mktemp -d)"
trap 'rm -rf "${temp_dir}"' EXIT

curl --fail --location --silent --show-error "${base_url}/${archive}" --output "${temp_dir}/${archive}"
curl --fail --location --silent --show-error "${base_url}/checksums.txt" --output "${temp_dir}/checksums.txt"

expected="$(awk -v archive="${archive}" '$2 == archive { print $1 }' "${temp_dir}/checksums.txt")"
actual="$(sha256sum "${temp_dir}/${archive}" | awk '{ print $1 }')"
if [[ -z "${expected}" || "${actual}" != "${expected}" ]]; then
  echo "TFLint checksum verification failed." >&2
  exit 1
fi

mkdir -p "${install_dir}"
unzip -oq "${temp_dir}/${archive}" -d "${install_dir}"
chmod +x "${install_dir}/tflint"
echo "##vso[task.prependpath]${install_dir}"
"${install_dir}/tflint" --version
