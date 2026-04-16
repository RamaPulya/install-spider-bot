#!/usr/bin/env bash

set -Eeuo pipefail

REPO_OWNER="${REPO_OWNER:-RamaPulya}"
REPO_NAME="${REPO_NAME:-install-spider-bot}"
REPO_BRANCH="${REPO_BRANCH:-spiderman}"
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-/tmp/bedolaga-installer-bootstrap}"
TARBALL_URL="${TARBALL_URL:-https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/refs/heads/${REPO_BRANCH}}"
GITHUB_OWNER_FALLBACK="${GITHUB_OWNER_FALLBACK:-RamaPulya}"
BOOTSTRAP_VERSION="${BOOTSTRAP_VERSION:-2026.04.16-5}"

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

  if ! command -v fuser >/dev/null 2>&1; then
    return 0
  fi

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

read_github_token() {
  local token=""
  local file

  for file in "/root/.config/bedolaga/installer.env" "/etc/bedolaga/installer.env"; do
    if [[ -f "${file}" ]]; then
      token="$(sed -n 's/^GITHUB_TOKEN=//p' "${file}" | tail -n 1)"
      token="${token%\"}"
      token="${token#\"}"
      if [[ -n "${token}" ]]; then
        printf '%s\n' "${token}"
        return 0
      fi
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
pattern = re.compile(r'(^[ \t]*read\b[^\n#]*?)((?:\s+-[A-Za-z0-9-]*)*?)\s+-s\b((?:\s+-[A-Za-z0-9-]*)*?)([^\n]*)$', re.MULTILINE)

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

path.write_text(pattern.sub(repl, text), encoding="utf-8", newline="\n")
PY
      changed=1
      log "Patched hidden prompt in: ${file#${repo_root}/}"
    fi
  done < <(find "${repo_root}" -type f \( -name '*.sh' -o -name '*.bash' \) -print0)

  if (( changed == 0 )); then
    log "No hidden secret prompts were found in installer scripts."
  fi
}

sanitize_single_key_prompts() {
  local repo_root="$1"
  local file
  local changed=0

  while IFS= read -r -d '' file; do
    if grep -Eq '(^|[[:space:]])read[[:space:]].*(-n[[:space:]]*1|-n1)([[:space:]]|$)' "${file}"; then
      cp "${file}" "${file}.bak"
      python3 - "${file}" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

text = re.sub(r'(\bread\b[^\n#]*?)\s+-n\s*1(?=[\s"]|$)', r'\1', text)
text = re.sub(r'(\bread\b[^\n#]*?)\s+-n1(?=[\s"]|$)', r'\1', text)
text = re.sub(r'[ \t]+$', '', text, flags=re.MULTILINE)

path.write_text(text, encoding="utf-8", newline="\n")
PY
      changed=1
      log "Patched single-key prompt in: ${file#${repo_root}/}"
    fi
  done < <(find "${repo_root}" -type f \( -name '*.sh' -o -name '*.bash' \) -print0)

  if (( changed == 0 )); then
    log "No single-key prompts were found in installer scripts."
  fi
}

patch_github_token_urls() {
  local repo_root="$1"
  local file
  local changed=0

  while IFS= read -r -d '' file; do
    if grep -Eq 'https://.+@github\.com/' "${file}"; then
      cp "${file}" "${file}.bak"
      python3 - "${file}" "${GITHUB_OWNER_FALLBACK}" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
owner = sys.argv[2]
text = path.read_text(encoding="utf-8")

text = re.sub(
    r'https://(\$\{?[A-Za-z_][A-Za-z0-9_]*\}?)(@github\.com/)',
    lambda m: f'https://{owner}:{m.group(1)}{m.group(2)}',
    text,
)
text = re.sub(
    r'https://(github_pat_[A-Za-z0-9_]+)(@github\.com/)',
    lambda m: f'https://{owner}:{m.group(1)}{m.group(2)}',
    text,
)
text = re.sub(
    r'https://(["\']?\$[A-Za-z_][A-Za-z0-9_]*["\']?)(@github\.com/)',
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

sanitize_git_invocations() {
  local repo_root="$1"
  local file
  local changed=0

  while IFS= read -r -d '' file; do
    if grep -Eq '/usr/bin/git|command[[:space:]]+git' "${file}"; then
      cp "${file}" "${file}.bak"
      sed -E -i \
        -e 's@/usr/bin/git@git@g' \
        -e 's@command[[:space:]]+git@git@g' \
        "${file}"
      changed=1
      log "Patched direct git invocation in: ${file#${repo_root}/}"
    fi
  done < <(find "${repo_root}" -type f \( -name '*.sh' -o -name '*.bash' \) -print0)

  if (( changed == 0 )); then
    log "No direct /usr/bin/git or command git invocations were found."
  fi
}

read_installer_version() {
  local repo_root="$1"
  local version_file=""

  for version_file in "${repo_root}/scripts/VERSION" "${repo_root}/VERSION"; do
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
  log "Interactive marker: QUICK=${BOOTSTRAP_VERSION} INSTALLER=${installer_version}"
}

inject_interactive_version_banner() {
  local repo_root="$1"
  local installer_version
  local file
  local changed=0

  installer_version="$(read_installer_version "${repo_root}")"

  while IFS= read -r -d '' file; do
    if grep -Fq 'Начать установку? (y/N):' "${file}" && ! grep -Fq 'Interactive marker:' "${file}"; then
      cp "${file}" "${file}.bak"
      python3 - "${file}" "${BOOTSTRAP_VERSION}" "${installer_version}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
bootstrap_version = sys.argv[2]
installer_version = sys.argv[3]
text = path.read_text(encoding="utf-8")

banner = (
    f'echo "Interactive marker: QUICK={bootstrap_version} INSTALLER={installer_version}"\n'
    f'echo "Bootstrap version: {bootstrap_version}"\n'
    f'echo "Installer version: {installer_version}"\n'
)

needle = 'read -p "Начать установку? (y/N):"'
if needle in text:
    text = text.replace(needle, banner + needle, 1)

path.write_text(text, encoding="utf-8", newline="\n")
PY
      changed=1
      log "Injected interactive version banner into: ${file#${repo_root}/}"
    fi
  done < <(find "${repo_root}" -type f \( -name '*.sh' -o -name '*.bash' \) -print0)

  if (( changed == 0 )); then
    log "No interactive install prompt was patched with version markers."
  fi
}

configure_global_github_auth() {
  local token=""
  local owner="${GITHUB_OWNER_FALLBACK}"

  token="$(read_github_token || true)"
  if [[ -z "${token}" ]]; then
    log "No GitHub token found for global auth configuration."
    return 0
  fi

  git config --global url."https://${owner}:${token}@github.com/".insteadOf "https://github.com/"
  git config --global url."https://${owner}:${token}@github.com/".insteadOf "https://${token}@github.com/"
  log "Configured global GitHub auth rewrite for HTTPS clone URLs."
}

preflight_private_repo_auth() {
  local token=""
  local target_repo="https://github.com/${GITHUB_OWNER_FALLBACK}/spiderbot.git"

  token="$(read_github_token || true)"
  if [[ -z "${token}" ]]; then
    log "No GitHub token found. Skipping private repo auth preflight."
    return 0
  fi

  log "Checking GitHub token access to ${GITHUB_OWNER_FALLBACK}/spiderbot..."
  if git ls-remote "${target_repo}" >/dev/null 2>&1; then
    log "GitHub token check passed."
    return 0
  fi

  fail "GitHub token check failed for ${target_repo}. The token is missing access to the private repo, expired, or invalid."
}

setup_git_wrapper() {
  local real_git
  local wrapper_dir
  local wrapper_path
  local askpass_path

  real_git="$(command -v git)"
  [[ -n "${real_git}" ]] || fail "git binary was not found in PATH."

  wrapper_dir="${BOOTSTRAP_DIR}/bin"
  wrapper_path="${wrapper_dir}/git"
  askpass_path="${wrapper_dir}/git-askpass.sh"
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

main() {
  local token=""
  local owner="\${GITHUB_OWNER_FALLBACK}"

  token="$(load_token || true)"
  if [[ -n "\${token}" ]]; then
    exec "\${REAL_GIT}" \
      -c "url.https://\${owner}:\${token}@github.com/.insteadOf=https://github.com/" \
      -c "url.https://\${owner}:\${token}@github.com/.insteadOf=https://\${token}@github.com/" \
      "\$@"
  fi

  exec "\${REAL_GIT}" "\$@"
}

main "\$@"
EOF

  cat > "${askpass_path}" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail

PROMPT="\${1:-}"
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

case "\${PROMPT}" in
  Username*|*Username*)
    printf '%s\n' "\${GITHUB_OWNER_FALLBACK}"
    ;;
  Password*|*Password*)
    load_token || printf '\n'
    ;;
  *)
    load_token || printf '\n'
    ;;
esac
EOF

  chmod +x "${wrapper_path}" "${askpass_path}"
  export PATH="${wrapper_dir}:${PATH}"
  export GIT_ASKPASS="${askpass_path}"
  export SSH_ASKPASS="${askpass_path}"
  export GIT_TERMINAL_PROMPT=0
}

main() {
  local repo_root
  local installer_path

  require_root "$@"
  print_banner

  log "Installing base packages..."
  apt_install ca-certificates curl wget git tar python3

  download_repo_tarball
  repo_root="$(find_repo_root)"
  installer_path="$(find_installer "${repo_root}")" || fail "install.sh was not found in the repository archive. Checked: install.sh, scripts/install.sh, installer/install.sh, .installer/install.sh"

  sanitize_system_upgrade_steps "${repo_root}"
  sanitize_hidden_secret_prompts "${repo_root}"
  sanitize_single_key_prompts "${repo_root}"
  patch_github_token_urls "${repo_root}"
  sanitize_git_invocations "${repo_root}"
  setup_git_wrapper
  configure_global_github_auth
  print_runtime_version "${repo_root}"
  inject_interactive_version_banner "${repo_root}"
  preflight_private_repo_auth

  chmod +x "${installer_path}"

  log "Running installer: ${installer_path#${repo_root}/}"
  cd "${repo_root}"
  exec bash "${installer_path}" "$@"
}

main "$@"
