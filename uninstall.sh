#!/usr/bin/env bash

#
# Uninstaller for pvm (Pod Version Manager)
#

{ # this ensures the entire script is downloaded #

pvm_echo() {
  command printf %s\\n "$*" 2>/dev/null
}

pvm_default_install_dir() {
  [ -z "${XDG_CONFIG_HOME-}" ] && pvm_echo "${HOME}/.pvm" || pvm_echo "${XDG_CONFIG_HOME}/pvm"
}

pvm_detect_profile() {
  local DETECTED_PROFILE
  DETECTED_PROFILE=''
  
  if [ -n "${PROFILE}" ] && [ -f "${PROFILE}" ]; then
    DETECTED_PROFILE="${PROFILE}"
  elif [ -n "${SHELL-}" ]; then
    case "${SHELL}" in
      *bash*)
        if [ -f "${HOME}/.bashrc" ]; then
          DETECTED_PROFILE="${HOME}/.bashrc"
        elif [ -f "${HOME}/.bash_profile" ]; then
          DETECTED_PROFILE="${HOME}/.bash_profile"
        fi
        ;;
      *zsh*)
        DETECTED_PROFILE="${HOME}/.zshrc"
        ;;
      *ksh*)
        DETECTED_PROFILE="${HOME}/.kshrc"
        ;;
    esac
  fi
  
  if [ -z "${DETECTED_PROFILE}" ]; then
    if [ -f "${HOME}/.profile" ]; then
      DETECTED_PROFILE="${HOME}/.profile"
    elif [ -f "${HOME}/.bashrc" ]; then
      DETECTED_PROFILE="${HOME}/.bashrc"
    elif [ -f "${HOME}/.bash_profile" ]; then
      DETECTED_PROFILE="${HOME}/.bash_profile"
    elif [ -f "${HOME}/.zshrc" ]; then
      DETECTED_PROFILE="${HOME}/.zshrc"
    fi
  fi
  
  if [ ! -z "${DETECTED_PROFILE}" ]; then
    pvm_echo "${DETECTED_PROFILE}"
  fi
}

pvm_echo "=> Uninstalling pvm..."

# 1. Remove pvm directory
if [ -n "${PVM_DIR-}" ]; then
  INSTALL_DIR="${PVM_DIR}"
else
  INSTALL_DIR="$(pvm_default_install_dir)"
fi

if [ -d "${INSTALL_DIR}" ]; then
  pvm_echo "=> Removing pvm directory: ${INSTALL_DIR}"
  rm -rf "${INSTALL_DIR}"
else
  pvm_echo "=> pvm directory not found: ${INSTALL_DIR}"
fi

# 2. Remove configuration from shell profile
PROFILE_FILE="$(pvm_detect_profile)"

if [ -n "${PROFILE_FILE}" ] && [ -f "${PROFILE_FILE}" ]; then
  pvm_echo "=> Removing pvm configuration from ${PROFILE_FILE}"
  
  # Create a temporary file
  TMP_FILE=$(mktemp)
  
  # Remove lines containing pvm configuration
  # The pattern matches:
  # - export PVM_DIR...
  # - [ -s "$PVM_DIR/pvm.sh" ]...
  # - [ -s "$PVM_DIR/bash_completion" ]...
  
  grep -v "export PVM_DIR=" "${PROFILE_FILE}" | \
  grep -v "\[ -s \"\$PVM_DIR/pvm.sh\" \]" | \
  grep -v "\[ -s \"\$PVM_DIR/bash_completion\" \]" > "${TMP_FILE}"
  
  # Check if file content changed
  if cmp -s "${PROFILE_FILE}" "${TMP_FILE}"; then
    pvm_echo "=> No pvm configuration found in ${PROFILE_FILE}"
  else
    mv "${TMP_FILE}" "${PROFILE_FILE}"
    pvm_echo "=> pvm configuration removed from ${PROFILE_FILE}"
  fi
  
  rm -f "${TMP_FILE}"
else
  pvm_echo "=> Could not detect shell profile. Please manually remove pvm configuration from your shell profile (e.g. .bashrc, .zshrc)."
fi

pvm_echo ""
pvm_echo "=> pvm has been uninstalled."
pvm_echo "=> Please restart your terminal for changes to take effect."

} # this ensures the entire script is downloaded #
