#!/usr/bin/env bash

{

pvm_has() {
  type "$1" > /dev/null 2>&1
}

pvm_echo() {
  command printf %s\n "$*" 2>/dev/null
}

get_pvm_source() {
  local PVM_SOURCE_URL
  PVM_SOURCE_URL="https://github.com/mohuwamg/pvm.git" # Placeholder URL
  pvm_echo "${PVM_SOURCE_URL}"
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

# Check for git
if ! pvm_has "git"; then
  pvm_echo >&2 "pvm installation requires git."
  exit 1
fi

# Set up installation directory
INSTALL_DIR="$(pvm_install_dir)"
if [ -d "${INSTALL_DIR}" ]; then
  pvm_echo "=> pvm is already installed in ${INSTALL_DIR}, trying to update..."
  pvm_echo -n "=> Cding to ${INSTALL_DIR}..."
  cd "${INSTALL_DIR}" || exit 1
  pvm_echo "done"
  pvm_echo -n "=> Pulling from remote..."
  git pull
  pvm_echo "done"
else
  pvm_echo "=> Downloading pvm from git to '${INSTALL_DIR}'"
  git clone "$(get_pvm_source)" "${INSTALL_DIR}"
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

SOURCE_STR='\nexport PVM_DIR="${INSTALL_DIR}"\n[ -s "$PVM_DIR/pvm.sh" ] && \. "$PVM_DIR/pvm.sh"  # This loads pvm\n'
COMPLETION_STR='[ -s "$PVM_DIR/bash_completion" ] && \. "$PVM_DIR/bash_completion"  # This loads pvm bash_completion\n'

if ! command grep -qc '/pvm.sh' "${PROFILE_FILE}"; then
  pvm_echo "=> Appending pvm source string to ${PROFILE_FILE}"
  command printf "${SOURCE_STR}" >> "${PROFILE_FILE}"
else
  pvm_echo "=> pvm source string already in ${PROFILE_FILE}"
fi

if ! command grep -qc '/bash_completion' "${PROFILE_FILE}"; then
  pvm_echo "=> Appending pvm bash_completion source string to ${PROFILE_FILE}"
  command printf "${COMPLETION_STR}" >> "${PROFILE_FILE}"
else
  pvm_echo "=> pvm bash_completion source string already in ${PROFILE_FILE}"
fi

pvm_echo "=> pvm has been installed. Please restart your shell or run the following command:"
pvm_echo "   source ${PROFILE_FILE}"
pvm_echo ""
pvm_echo "=> To use pvm, run: pvm install <version> && pvm use <version>"

} # this ensures the entire script is downloaded #
