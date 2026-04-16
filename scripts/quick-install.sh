#!/usr/bin/env bash

set -Eeuo pipefail

REPO_OWNER="${REPO_OWNER:-RamaPulya}"
REPO_NAME="${REPO_NAME:-install-spider-bot}"
REPO_BRANCH="${REPO_BRANCH:-spiderman}"
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-/tmp/bedolaga-installer-bootstrap}"
TARBALL_URL="${TARBALL_URL:-https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/refs/heads/${REPO_BRANCH}}"
GITHUB_OWNER_FALLBACK="${GITHUB_OWNER_FALLBACK:-RamaPulya}"

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
  setup_git_wrapper

  chmod +x "${installer_path}"

  log "Running installer: ${installer_path#${repo_root}/}"
  cd "${repo_root}"
  exec bash "${installer_path}" "$@"
}

main "$@"
