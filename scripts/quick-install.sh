#!/usr/bin/env bash

set -Eeuo pipefail

REPO_OWNER="${REPO_OWNER:-RamaPulya}"
REPO_NAME="${REPO_NAME:-install-spider-bot}"
REPO_BRANCH="${REPO_BRANCH:-spiderman}"
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-/tmp/bedolaga-installer-bootstrap}"
TARBALL_URL="${TARBALL_URL:-https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/refs/heads/${REPO_BRANCH}}"
GITHUB_OWNER_FALLBACK="${GITHUB_OWNER_FALLBACK:-RamaPulya}"
BOOTSTRAP_VERSION="${BOOTSTRAP_VERSION:-2026.04.16-3}"

APT_INSTALL_OPTS=(
  -y
  -o Dpkg::Options::=--force-confdef
  -o Dpkg::Options::=--force-confold
)

log() {
  printf '%s\n' "$*"
}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

print_banner() {
  cat <<'EOF'
============================================================
REMNAWAVE BEDOLAGA BOT - QUICK INSTALL
============================================================
EOF
  log "Bootstrap version: ${BOOTSTRAP_VERSION}"
  log "Repository: ${REPO_OWNER}/${REPO_NAME}@${REPO_BRANCH}"
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    exec sudo -E bash "$0" "$@"
  fi
}

wait_for_dpkg_lock() {
  local attempts=0

  while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if (( attempts > 90 )); then
      fail "dpkg lock is held for too long. Finish or stop the other apt process and rerun the installer."
    fi

    log "Waiting for another apt/dpkg process to finish..."
    sleep 2
  done
}

apt_install() {
  export DEBIAN_FRONTEND=noninteractive

  wait_for_dpkg_lock
  apt-get update

  wait_for_dpkg_lock
  apt-get install "${APT_INSTALL_OPTS[@]}" "$@"
}

download_repo_tarball() {
  local tarball_path="${BOOTSTRAP_DIR}/repo.tar.gz"

  rm -rf "${BOOTSTRAP_DIR}"
  mkdir -p "${BOOTSTRAP_DIR}"

  log "Downloading installer repository archive..."
  curl -fL "${TARBALL_URL}" -o "${tarball_path}"
  tar -xzf "${tarball_path}" -C "${BOOTSTRAP_DIR}"
}

find_repo_root() {
  local repo_root

  repo_root="$(find "${BOOTSTRAP_DIR}" -mindepth 1 -maxdepth 1 -type d -name "${REPO_NAME}-*" | head -n 1 || true)"
  [[ -n "${repo_root}" ]] || fail "Repository archive was downloaded but the extracted directory was not found."

  printf '%s\n' "${repo_root}"
}

find_installer() {
  local repo_root="$1"
  local candidate

  for candidate in \
    "install.sh" \
    "scripts/install.sh" \
    "installer/install.sh" \
    ".installer/install.sh"
  do
    if [[ -f "${repo_root}/${candidate}" ]]; then
      printf '%s\n' "${repo_root}/${candidate}"
      return 0
    fi
  done

  return 1
}

sanitize_system_upgrade_steps() {
  local repo_root="$1"
  local file
  local changed=0

  while IFS= read -r -d '' file; do
    if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(apt|apt-get)[[:space:]]+(upgrade|dist-upgrade|full-upgrade)\b|^[[:space:]]*(sudo[[:space:]]+)?do-release-upgrade\b' "${file}"; then
      cp "${file}" "${file}.bak"
      sed -E -i \
        -e 's@^([[:space:]]*)(sudo[[:space:]]+)?(apt|apt-get)[[:space:]]+(upgrade|dist-upgrade|full-upgrade)\b(.*)$@\1echo "Skipping full OS upgrade: \3 \4\5"@' \
        -e 's@^([[:space:]]*)(sudo[[:space:]]+)?do-release-upgrade\b(.*)$@\1echo "Skipping Ubuntu release upgrade\3"@' \
        "${file}"
      changed=1
      log "Patched system upgrade step in: ${file#${repo_root}/}"
    fi
  done < <(find "${repo_root}" -type f \( -name '*.sh' -o -name '*.bash' \) -print0)

  if (( changed == 0 )); then
    log "No full OS upgrade commands were found in installer scripts."
  fi
}

sanitize_hidden_secret_prompts() {
  local repo_root="$1"
  local file
  local changed=0

  while IFS= read -r -d '' file; do
    if grep -Eq '(^|[[:space:]])read[[:space:]].*-s([[:space:]]|$)' "${file}"; then
      cp "${file}" "${file}.bak"
      python3 - "${file}" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

pattern = re.compile(r'(^[ \t]*read\b[^\n#]*?)((?:\s+-[A-Za-z-]*)*?)\s+-s\b((?:\s+-[A-Za-z-]*)*?)([^\n]*)$', re.MULTILINE)

def repl(match):
    before = match.group(1)
    left = match.group(2) or ""
    right = match.group(3) or ""
    tail = match.group(4) or ""
    options = f"{left}{right}"
    options = re.sub(r'\s+', ' ', options).rstrip()
    if options:
        return f"{before}{options}{tail}"
    return f"{before}{tail}"

new_text = pattern.sub(repl, text)
path.write_text(new_text, encoding="utf-8", newline="\n")
PY
      changed=1
      log "Patched hidden prompt in: ${file#${repo_root}/}"
    fi
  done < <(find "${repo_root}" -type f \( -name '*.sh' -o -name '*.bash' \) -print0)

  if (( changed == 0 )); then
    log "No hidden secret prompts were found in installer scripts."
  fi
}

patch_github_token_urls() {
  local repo_root="$1"
  local file
  local changed=0

  while IFS= read -r -d '' file; do
    if grep -Eq 'https://(\$\{?[A-Za-z_][A-Za-z0-9_]*\}?|github_pat_[A-Za-z0-9_]+)@github\.com/' "${file}"; then
      cp "${file}" "${file}.bak"
      python3 - "${file}" "${GITHUB_OWNER_FALLBACK}" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
owner = sys.argv[2]
text = path.read_text(encoding="utf-8")

# https://${VAR}@github.com/org/repo.git -> https://owner:${VAR}@github.com/org/repo.git
text = re.sub(
    r'https://(\$\{?[A-Za-z_][A-Za-z0-9_]*\}?)(@github\.com/)',
    lambda m: f'https://{owner}:{m.group(1)}{m.group(2)}',
    text,
)

# https://github_pat_xxx@github.com/org/repo.git -> https://owner:github_pat_xxx@github.com/org/repo.git
text = re.sub(
    r'https://(github_pat_[A-Za-z0-9_]+)(@github\.com/)',
    lambda m: f'https://{owner}:{m.group(1)}{m.group(2)}',
    text,
)

path.write_text(text, encoding="utf-8", newline="\n")
PY
      changed=1
      log "Patched GitHub token URL in: ${file#${repo_root}/}"
    fi
  done < <(find "${repo_root}" -type f \( -name '*.sh' -o -name '*.bash' -o -name '*.env' \) -print0)

  if (( changed == 0 )); then
    log "No broken GitHub token URLs were found in installer files."
  fi
}

read_installer_version() {
  local repo_root="$1"
  local version_file=""

  for version_file in \
    "${repo_root}/scripts/VERSION" \
    "${repo_root}/VERSION"
  do
    if [[ -f "${version_file}" ]]; then
      tr -d '\r' < "${version_file}" | head -n 1
      return 0
    fi
  done

  printf 'unknown\n'
}

print_runtime_version() {
  local repo_root="$1"
  local installer_version

  installer_version="$(read_installer_version "${repo_root}")"
  log "Installer version: ${installer_version}"
  log "Update marker: bootstrap ${BOOTSTRAP_VERSION} / installer ${installer_version}"
}

setup_git_wrapper() {
  local real_git
  local wrapper_dir
  local wrapper_path

  real_git="$(command -v git)"
  [[ -n "${real_git}" ]] || fail "git binary was not found in PATH."

  wrapper_dir="${BOOTSTRAP_DIR}/bin"
  wrapper_path="${wrapper_dir}/git"
  mkdir -p "${wrapper_dir}"

  cat > "${wrapper_path}" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail

REAL_GIT="${real_git}"
TOKEN_FILE_USER="/root/.config/bedolaga/installer.env"
TOKEN_FILE_SYSTEM="/etc/bedolaga/installer.env"
GITHUB_OWNER_FALLBACK="${GITHUB_OWNER_FALLBACK}"

load_token() {
  local token=""
  local file

  for file in "\${TOKEN_FILE_USER}" "\${TOKEN_FILE_SYSTEM}"; do
    if [[ -f "\${file}" ]]; then
      token="$(sed -n 's/^GITHUB_TOKEN=//p' "\${file}" | tail -n 1)"
      token="\${token%\"}"
      token="\${token#\"}"
      if [[ -n "\${token}" ]]; then
        printf '%s\n' "\${token}"
        return 0
      fi
    fi
  done

  return 1
}

rewrite_url() {
  local token="\$1"
  local arg="\$2"
  local owner="\${GITHUB_OWNER_FALLBACK}"
  local path_part

  if [[ "\${arg}" =~ ^https://([^/@:]+@)?github\\.com/(.+)\$ ]]; then
    path_part="\${BASH_REMATCH[2]}"
    if [[ "\${path_part}" =~ ^([^/]+)/.+$ ]]; then
      owner="\${BASH_REMATCH[1]}"
    fi
    printf 'https://%s:%s@github.com/%s\n' "\${owner}" "\${token}" "\${path_part}"
    return 0
  fi

  printf '%s\n' "\${arg}"
}

main() {
  local token=""
  local arg
  local rewritten=()

  token="$(load_token || true)"

  if [[ -z "\${token}" ]]; then
    exec "\${REAL_GIT}" "\$@"
  fi

  for arg in "\$@"; do
    rewritten+=("$(rewrite_url "\${token}" "\${arg}")")
  done

  exec "\${REAL_GIT}" "\${rewritten[@]}"
}

main "\$@"
EOF

  chmod +x "${wrapper_path}"
  export PATH="${wrapper_dir}:${PATH}"
  export BEDOLAGA_REAL_GIT="${real_git}"
}

main() {
  local repo_root
  local installer_path

  require_root "$@"
  print_banner

  log "Installing base packages..."
  apt_install ca-certificates curl wget git tar

  download_repo_tarball
  repo_root="$(find_repo_root)"
  installer_path="$(find_installer "${repo_root}")" || fail "install.sh was not found in the repository archive. Checked: install.sh, scripts/install.sh, installer/install.sh, .installer/install.sh"
  sanitize_system_upgrade_steps "${repo_root}"
  sanitize_hidden_secret_prompts "${repo_root}"
  patch_github_token_urls "${repo_root}"
  setup_git_wrapper
  print_runtime_version "${repo_root}"

  chmod +x "${installer_path}"

  log "Running installer: ${installer_path#${repo_root}/}"
  cd "${repo_root}"
  exec bash "${installer_path}" "$@"
}

main "$@"
