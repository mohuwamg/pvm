#!/usr/bin/env bash

{

pvm_has() {
  type "$1" > /dev/null 2>&1
}

pvm_echo() {
  command printf %s\n "$*" 2>/dev/null
}

pvm_source_local() {
  local DIR
  DIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"
  pvm_echo "${DIR}"
}

pvm_install_dir() {
  if [ -n "${PVM_DIR-}" ]; then
    pvm_echo "${PVM_DIR}"
  elif [ -n "${XDG_CONFIG_HOME-}" ]; then
    pvm_echo "${XDG_CONFIG_HOME}/pvm"
  else
    pvm_echo "${HOME}/.pvm"
  fi
}

# Set up installation directory
INSTALL_DIR="$(pvm_install_dir)"
if [ "${INSTALL_DIR##*/}" = ".pvmn" ]; then
  INSTALL_DIR="${INSTALL_DIR%n}"
fi
mkdir -p "${INSTALL_DIR}"
cp -f "./pvm.sh" "${INSTALL_DIR}/pvm.sh" 2>/dev/null || true
if [ -f "./bash_completion" ]; then
  cp -f "./bash_completion" "${INSTALL_DIR}/bash_completion"
fi

# Set up shell profile
PROFILE_FILE=""
if [ -n "${PROFILE-}" ] && [ -f "${PROFILE-}" ]; then
  PROFILE_FILE="${PROFILE-}"
elif pvm_has "zsh"; then
  PROFILE_FILE="${HOME}/.zshrc"
elif pvm_has "bash"; then
  PROFILE_FILE="${HOME}/.bashrc"
elif pvm_has "ksh"; then
  PROFILE_FILE="${HOME}/.kshrc"
else
  pvm_echo >&2 "pvm: could not detect shell profile file."
  pvm_echo >&2 "Please add the following lines to your shell profile file:"
  pvm_echo >&2 'export PVM_DIR="${INSTALL_DIR}"'
  pvm_echo >&2 '[ -s "$PVM_DIR/pvm.sh" ] && \. "$PVM_DIR/pvm.sh"  # This loads pvm'
  pvm_echo >&2 '[ -s "$PVM_DIR/bash_completion" ] && \. "$PVM_DIR/bash_completion"  # This loads pvm bash_completion'
  exit 1
fi

SOURCE_STR="export PVM_DIR=\"${INSTALL_DIR}\"\n[ -s \"\$PVM_DIR/pvm.sh\" ] && . \"\$PVM_DIR/pvm.sh\"\n"
COMPLETION_STR="[ -s \"\$PVM_DIR/bash_completion\" ] && . \"\$PVM_DIR/bash_completion\"\n"

if [ ! -f "${PROFILE_FILE}" ]; then
  : > "${PROFILE_FILE}"
fi
if [ ! -f "${PROFILE_FILE}" ]; then : > "${PROFILE_FILE}"; fi
if ! command grep -qc '/pvm.sh' "${PROFILE_FILE}"; then
  command printf "%b" "${SOURCE_STR}" >> "${PROFILE_FILE}"
fi

if ! command grep -qc '/bash_completion' "${PROFILE_FILE}"; then
  command printf "%b" "${COMPLETION_STR}" >> "${PROFILE_FILE}"
fi

cat <<EOF
pvm path: ${INSTALL_DIR}
Next: source ${PROFILE_FILE}
Use: pvm install <version> && pvm use <version>
EOF

} # this ensures the entire script is downloaded #
