#!/usr/bin/env bash

{ # this ensures the entire script is downloaded #

pvm_has() {
  type "$1" > /dev/null 2>&1
}

pvm_echo() {
  command printf %s\\n "$*" 2>/dev/null
}

pvm_grep() {
  GREP_OPTIONS='' command grep "$@"
}

pvm_default_install_dir() {
  [ -z "${XDG_CONFIG_HOME-}" ] && pvm_echo "${HOME}/.pvm" || pvm_echo "${XDG_CONFIG_HOME}/pvm"
}

pvm_install_dir() {
  if [ -n "${PVM_DIR-}" ]; then
    pvm_echo "${PVM_DIR}"
  else
    pvm_default_install_dir
  fi
}

pvm_latest_version() {
  pvm_echo "main"
}

pvm_source() {
  pvm_echo "https://raw.githubusercontent.com/mohuwamg/pvm/$(pvm_latest_version)/pvm.sh"
}

pvm_completion_source() {
  pvm_echo "https://raw.githubusercontent.com/mohuwamg/pvm/$(pvm_latest_version)/bash_completion"
}

pvm_download() {
  if pvm_has "curl"; then
    curl -q -o "$2" -sSL "$1"
  elif pvm_has "wget"; then
    wget -qO "$2" "$1"
  else
    pvm_echo >&2 "pvm: curl or wget is required to install pvm"
    return 1
  fi
}

install_pvm_from_git() {
  local INSTALL_DIR
  INSTALL_DIR="$1"
  
  if [ -d "${INSTALL_DIR}/.git" ]; then
    pvm_echo "=> pvm is already installed in ${INSTALL_DIR}, trying to update using git"
    command printf '\r=> '
    cd "${INSTALL_DIR}" && (command git fetch 2> /dev/null || {
      pvm_echo >&2 "FAILED: git fetch failed" 
      return 1
    }) && command git checkout -qf $(pvm_latest_version) && command git branch --set-upstream-to=origin/$(pvm_latest_version) $(pvm_latest_version) && command git reset --hard origin/$(pvm_latest_version) || {
      pvm_echo >&2 "FAILED: git operations failed"
      return 1
    }
  else
    pvm_echo "=> Downloading pvm from git to '${INSTALL_DIR}'"
    command printf '\r=> '
    mkdir -p "${INSTALL_DIR}"
    if [ "$(ls -A "${INSTALL_DIR}")" ]; then
      pvm_echo >&2 "FAILED: ${INSTALL_DIR} is not empty"
      return 1
    fi
    command git clone -q -b $(pvm_latest_version) https://github.com/mohuwamg/pvm.git "${INSTALL_DIR}" || {
      pvm_echo >&2 "FAILED: git clone failed"
      return 1
    }
  fi
  return 0
}

#
# Main Install Logic
#

INSTALL_DIR="$(pvm_install_dir)"
mkdir -p "${INSTALL_DIR}"

# Check if we can use git (preferred)
if pvm_has "git"; then
  install_pvm_from_git "${INSTALL_DIR}"
else
  # Fallback to downloading files manually
  pvm_echo "=> Downloading pvm scripts to '${INSTALL_DIR}'"
  
  # Detect if we are running from a local repo
  LOCAL_PVM_SCRIPT="$(cd "$(dirname "$0")" 2>/dev/null && pwd)/pvm.sh"
  if [ -f "${LOCAL_PVM_SCRIPT}" ]; then
    pvm_echo "=> Detected local pvm.sh, copying..."
    cp -f "${LOCAL_PVM_SCRIPT}" "${INSTALL_DIR}/pvm.sh"
    [ -f "$(dirname "${LOCAL_PVM_SCRIPT}")/bash_completion" ] && cp -f "$(dirname "${LOCAL_PVM_SCRIPT}")/bash_completion" "${INSTALL_DIR}/bash_completion"
  else
    # Download from GitHub
    pvm_download "$(pvm_source)" "${INSTALL_DIR}/pvm.sh" || {
      pvm_echo >&2 "FAILED: Failed to download pvm.sh"
      exit 1
    }
    pvm_download "$(pvm_completion_source)" "${INSTALL_DIR}/bash_completion" || {
      pvm_echo >&2 "FAILED: Failed to download bash_completion"
      exit 1
    }
  fi
fi

# Make sure the script is executable (though we source it)
chmod a+x "${INSTALL_DIR}/pvm.sh" 2>/dev/null

#
# Profile Configuration
#

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

PROFILE_FILE="$(pvm_detect_profile)"

pvm_echo "=> Appending pvm source string to ${PROFILE_FILE}"

if [ -z "${PROFILE_FILE}" ] || [ ! -f "${PROFILE_FILE}" ]; then
  if [ -z "${PROFILE_FILE}" ]; then
    pvm_echo "=> Profile not found. Tried ${HOME}/.bashrc, ${HOME}/.zshrc, ${HOME}/.profile, etc."
    pvm_echo "=> Create one of them and run this script again"
    pvm_echo "   OR"
    pvm_echo "=> Append the following lines to the correct file yourself:"
  else
    pvm_echo "=> Profile ${PROFILE_FILE} not found"
    pvm_echo "=> Append the following lines to the correct file yourself:"
  fi
  pvm_echo ""
  pvm_echo "export PVM_DIR=\"${INSTALL_DIR}\""
  pvm_echo '[ -s "$PVM_DIR/pvm.sh" ] && \. "$PVM_DIR/pvm.sh"  # This loads pvm'
  pvm_echo '[ -s "$PVM_DIR/bash_completion" ] && \. "$PVM_DIR/bash_completion"  # This loads pvm bash_completion'
  pvm_echo ""
  exit 1
fi

# Append to profile
SOURCE_STR="\\nexport PVM_DIR=\"${INSTALL_DIR}\"\\n[ -s \"\$PVM_DIR/pvm.sh\" ] && \\. \"\$PVM_DIR/pvm.sh\"  # This loads pvm\\n[ -s \"\$PVM_DIR/bash_completion\" ] && \\. \"\$PVM_DIR/bash_completion\"  # This loads pvm bash_completion\\n"

if ! command grep -qc '/pvm.sh' "${PROFILE_FILE}"; then
  command printf "${SOURCE_STR}" >> "${PROFILE_FILE}"
  pvm_echo "=> Added pvm to ${PROFILE_FILE}"
else
  pvm_echo "=> pvm is already in ${PROFILE_FILE}"
fi

pvm_echo "=> Close and reopen your terminal to start using pvm or run the following to use it now:"
pvm_echo ""
pvm_echo "export PVM_DIR=\"${INSTALL_DIR}\""
pvm_echo "[ -s \"\$PVM_DIR/pvm.sh\" ] && . \"\$PVM_DIR/pvm.sh\""
pvm_echo ""

} # this ensures the entire script is downloaded #
