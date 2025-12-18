#!/usr/bin/env bash

# Pod Version Manager
# Implemented as a POSIX-compliant function
# Should work on sh, dash, bash, ksh, zsh
# To use source this file from your bash profile

{ # this ensures the entire script is downloaded #

PVM_SCRIPT_SOURCE="$_"

pvm_is_zsh() {
  [ -n "${ZSH_VERSION-}" ]
}

pvm_echo() {
  command printf %s\\n "$*" 2>/dev/null
}

pvm_err() {
  >&2 pvm_echo "$@"
}

pvm_grep() {
  GREP_OPTIONS='' command grep "$@"
}

pvm_has() {
  type "${1-}" >/dev/null 2>&1
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

pvm_version_dir() {
  local PVM_DIR
  PVM_DIR="$(pvm_install_dir)"
  pvm_echo "${PVM_DIR}/versions/cocoapods"
}

pvm_alias_path() {
  local PVM_DIR
  PVM_DIR="$(pvm_install_dir)"
  pvm_echo "${PVM_DIR}/alias"
}

pvm_version_path() {
  local VERSION
  VERSION="${1}"
  if [ -z "${VERSION}" ]; then
    pvm_err "version is required"
    return 1
  fi
  local PVM_VERSION_DIR
  PVM_VERSION_DIR="$(pvm_version_dir)"
  pvm_echo "${PVM_VERSION_DIR}/${VERSION}"
}

pvm_ensure_version_installed() {
  local PROVIDED_VERSION
  PROVIDED_VERSION="${1}"
  local LOCAL_VERSION
  LOCAL_VERSION="$(pvm_version "${PROVIDED_VERSION}")"
  local VERSION_PATH
  VERSION_PATH="$(pvm_version_path "${LOCAL_VERSION}")"
  if [ ! -d "${VERSION_PATH}" ]; then
    pvm_err "Version ${LOCAL_VERSION} is not installed."
    pvm_err "You need to run 'pvm install ${LOCAL_VERSION}' to install it before using it."
    return 1
  fi
}

pvm_ls_current() {
  local PVM_CURRENT
  PVM_CURRENT="${PVM_COCOAPODS_VERSION:-}"
  if [ -z "${PVM_CURRENT}" ]; then
    pvm_echo "none"
  else
    pvm_echo "${PVM_CURRENT}"
  fi
}

pvm_resolve_alias() {
  local ALIAS
  ALIAS="${1}"
  if [ -z "${ALIAS}" ]; then
    return 1
  fi
  
  local ALIAS_PATH
  ALIAS_PATH="$(pvm_alias_path)"
  
  if [ -f "${ALIAS_PATH}/${ALIAS}" ]; then
    cat "${ALIAS_PATH}/${ALIAS}"
    return 0
  fi
  
  pvm_echo "${ALIAS}"
}

pvm_version() {
  local PATTERN
  PATTERN="${1}"
  local VERSION
  
  # Check if it's an alias
  VERSION="$(pvm_resolve_alias "${PATTERN}")"
  
  if [ "_${VERSION}" = "_${PATTERN}" ]; then
    # Not an alias, use as-is
    pvm_echo "${PATTERN}"
  else
    pvm_echo "${VERSION}"
  fi
}

pvm_version_remote() {
  local PATTERN
  PATTERN="${1}"
  
  if [ "${PATTERN}" = "latest" ]; then
    pvm_remote_latest
  else
    pvm_version "${PATTERN}"
  fi
}

pvm_remote_latest() {
  local LATEST
  if pvm_has "gem"; then
    LATEST="$(gem search '^cocoapods$' --remote --all | pvm_grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    if [ -n "${LATEST}" ]; then
      pvm_echo "${LATEST}"
      return 0
    fi
  fi
  pvm_err "Unable to retrieve latest version"
  return 1
}

pvm_ls_remote() {
  if ! pvm_has "gem"; then
    pvm_err "gem command not found. Please install Ruby first."
    return 1
  fi
  
  pvm_echo "Available CocoaPods versions:"
  gem search '^cocoapods$' --remote --all | pvm_grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V -r
}

pvm_ls() {
  local PVM_VERSION_DIR
  PVM_VERSION_DIR="$(pvm_version_dir)"
  local CURRENT
  CURRENT="$(pvm_ls_current)"
  
  if [ ! -d "${PVM_VERSION_DIR}" ] || [ -z "$(command ls -A "${PVM_VERSION_DIR}")" ]; then
    pvm_echo "No versions installed yet."
    return 0
  fi
  
  pvm_echo "Installed CocoaPods versions:"
  for VERSION_DIR in "${PVM_VERSION_DIR}"/*; do
    if [ -d "${VERSION_DIR}" ]; then
      local VERSION
      VERSION="$(basename "${VERSION_DIR}")"
      if [ "${VERSION}" = "${CURRENT}" ]; then
        pvm_echo "* ${VERSION} (currently using)"
      else
        pvm_echo "  ${VERSION}"
      fi
    fi
  done
  
  # Show aliases
  local ALIAS_PATH
  ALIAS_PATH="$(pvm_alias_path)"
  if [ -d "${ALIAS_PATH}" ] && [ -n "$(command ls -A "${ALIAS_PATH}")" ]; then
    pvm_echo ""
    pvm_echo "Aliases:"
    for ALIAS_FILE in "${ALIAS_PATH}"/*; do
      local ALIAS_NAME
      ALIAS_NAME="$(basename "${ALIAS_FILE}")"
      local ALIAS_TARGET
      ALIAS_TARGET="$(cat "${ALIAS_FILE}")"
      pvm_echo "  ${ALIAS_NAME} -> ${ALIAS_TARGET}"
    done
  fi
}

pvm_install() {
  local VERSION
  VERSION="${1}"
  
  if [ -z "${VERSION}" ]; then
    pvm_err "Usage: pvm install <version>"
    return 1
  fi
  
  if ! pvm_has "gem"; then
    pvm_err "gem command not found. Please install Ruby first."
    return 1
  fi
  
  # Resolve version
  local RESOLVED_VERSION
  RESOLVED_VERSION="$(pvm_version_remote "${VERSION}")"
  
  if [ -z "${RESOLVED_VERSION}" ]; then
    pvm_err "Unable to resolve version: ${VERSION}"
    return 1
  fi
  
  local VERSION_PATH
  VERSION_PATH="$(pvm_version_path "${RESOLVED_VERSION}")"
  
  if [ -d "${VERSION_PATH}" ]; then
    pvm_err "Version ${RESOLVED_VERSION} is already installed."
    # Even if installed, check default alias
    if [ ! -f "$(pvm_alias_path)/default" ]; then
      pvm_alias default "${RESOLVED_VERSION}"
    fi
    return 0
  fi
  
  pvm_echo "Installing CocoaPods ${RESOLVED_VERSION}..."
  
  # Create version directory
  mkdir -p "${VERSION_PATH}"
  
  # Set GEM_HOME for this installation
  local OLD_GEM_HOME="${GEM_HOME:-}"
  local OLD_GEM_PATH="${GEM_PATH:-}"
  export GEM_HOME="${VERSION_PATH}"
  export GEM_PATH="${VERSION_PATH}"
  
  # Install cocoapods
  local MIRROR="${PVM_RUBY_MIRROR:-}"
  local GEM_SOURCE=""
  if [ -n "${MIRROR}" ]; then
    GEM_SOURCE="--source ${MIRROR}"
  fi
  
  if gem install cocoapods -v "${RESOLVED_VERSION}" --no-document ${GEM_SOURCE}; then
    pvm_echo "Successfully installed CocoaPods ${RESOLVED_VERSION}"
    
    # Restore GEM_HOME
    if [ -n "${OLD_GEM_HOME}" ]; then
      export GEM_HOME="${OLD_GEM_HOME}"
      export GEM_PATH="${OLD_GEM_PATH}"
    else
      unset GEM_HOME
      unset GEM_PATH
    fi
    
    # Set default alias if it doesn't exist
    if [ ! -f "$(pvm_alias_path)/default" ]; then
      pvm_alias default "${RESOLVED_VERSION}"
    fi
    
    return 0
  else
    pvm_err "Failed to install CocoaPods ${RESOLVED_VERSION}"
    
    # Restore GEM_HOME
    if [ -n "${OLD_GEM_HOME}" ]; then
      export GEM_HOME="${OLD_GEM_HOME}"
      export GEM_PATH="${OLD_GEM_PATH}"
    else
      unset GEM_HOME
      unset GEM_PATH
    fi
    
    # Clean up failed installation
    rm -rf "${VERSION_PATH}"
    return 1
  fi
}

pvm_strip_path() {
  local OLD_PATH="${1}"
  local TO_STRIP="${2}"
  
  local NEW_PATH=""
  local IFS=':'
  for p in ${OLD_PATH}; do
    if [ "${p}" != "${TO_STRIP}" ] && [[ "${p}" != *".pvm/versions/cocoapods"* ]]; then
      if [ -z "${NEW_PATH}" ]; then
        NEW_PATH="${p}"
      else
        NEW_PATH="${NEW_PATH}:${p}"
      fi
    fi
  done
  echo "${NEW_PATH}"
}

pvm_use() {
  local VERSION
  VERSION="${1}"
  
  # If no version specified, try to read from .pvmrc
  if [ -z "${VERSION}" ]; then
    if [ -f .pvmrc ]; then
      VERSION="$(cat .pvmrc | pvm_grep -v '^#' | pvm_grep -v '^$' | head -1)"
    fi
  fi
  
  if [ -z "${VERSION}" ]; then
    pvm_err "Usage: pvm use <version>"
    pvm_err "Or create a .pvmrc file in the current directory"
    return 1
  fi
  
  if [ "${VERSION}" = "system" ]; then
    pvm_unload
    return 0
  fi
  
  # Resolve version
  local RESOLVED_VERSION
  RESOLVED_VERSION="$(pvm_version "${VERSION}")"
  
  # Check if version is installed
  if ! pvm_ensure_version_installed "${RESOLVED_VERSION}"; then
    return 1
  fi
  
  local VERSION_PATH
  VERSION_PATH="$(pvm_version_path "${RESOLVED_VERSION}")"
  
  # Set environment variables
  export GEM_HOME="${VERSION_PATH}"
  export GEM_PATH="${VERSION_PATH}"
  export PVM_COCOAPODS_VERSION="${RESOLVED_VERSION}"
  
  # Update PATH
  # First remove any existing pvm paths
  local CLEAN_PATH
  CLEAN_PATH="$(pvm_strip_path "${PATH}")"
  
  # If CLEAN_PATH is empty (unlikely but possible), set default system paths
  if [ -z "${CLEAN_PATH}" ]; then
    CLEAN_PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  fi
  
  # Add new version to PATH
  export PATH="${VERSION_PATH}/bin:${CLEAN_PATH}"
  
  pvm_echo "Now using CocoaPods ${RESOLVED_VERSION}"
  
  # Verify
  if pvm_has "pod"; then
    local POD_VERSION
    POD_VERSION="$(pod --version 2>/dev/null)"
    if [ "${POD_VERSION}" != "${RESOLVED_VERSION}" ]; then
      pvm_err "Warning: pod --version reports ${POD_VERSION}, expected ${RESOLVED_VERSION}"
    fi
  fi
}

pvm_unload() {
  unset GEM_HOME
  unset GEM_PATH
  unset PVM_COCOAPODS_VERSION
  
  local CLEAN_PATH
  CLEAN_PATH="$(pvm_strip_path "${PATH}")"
  
  if [ -z "${CLEAN_PATH}" ]; then
    CLEAN_PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  fi
  
  export PATH="${CLEAN_PATH}"
  pvm_echo "pvm unloaded. Using system CocoaPods (if available)."
}

pvm_uninstall() {
  local VERSION
  VERSION="${1}"
  
  if [ -z "${VERSION}" ]; then
    pvm_err "Usage: pvm uninstall <version>"
    return 1
  fi
  
  # Resolve version
  local RESOLVED_VERSION
  RESOLVED_VERSION="$(pvm_version "${VERSION}")"
  
  local VERSION_PATH
  VERSION_PATH="$(pvm_version_path "${RESOLVED_VERSION}")"
  
  if [ ! -d "${VERSION_PATH}" ]; then
    pvm_err "Version ${RESOLVED_VERSION} is not installed."
    return 1
  fi
  
  # Check if it's the current version
  local CURRENT
  CURRENT="$(pvm_ls_current)"
  if [ "${CURRENT}" = "${RESOLVED_VERSION}" ]; then
    pvm_err "Cannot uninstall currently active version: ${RESOLVED_VERSION}"
    pvm_err "Please switch to another version first with 'pvm use <version>'"
    return 1
  fi
  
  pvm_echo "Uninstalling CocoaPods ${RESOLVED_VERSION}..."
  rm -rf "${VERSION_PATH}"
  pvm_echo "Successfully uninstalled CocoaPods ${RESOLVED_VERSION}"
}

pvm_current() {
  local CURRENT
  CURRENT="$(pvm_ls_current)"
  if [ "${CURRENT}" = "none" ]; then
    pvm_echo "No version is currently active."
    pvm_echo "Use 'pvm use <version>' to activate a version."
  else
    pvm_echo "${CURRENT}"
  fi
}

pvm_alias() {
  local ALIAS_NAME
  ALIAS_NAME="${1}"
  local VERSION
  VERSION="${2}"
  
  if [ -z "${ALIAS_NAME}" ] || [ -z "${VERSION}" ]; then
    pvm_err "Usage: pvm alias <name> <version>"
    return 1
  fi
  
  # Resolve version
  local RESOLVED_VERSION
  RESOLVED_VERSION="$(pvm_version "${VERSION}")"
  
  # Check if version exists
  if ! pvm_ensure_version_installed "${RESOLVED_VERSION}"; then
    return 1
  fi
  
  local ALIAS_PATH
  ALIAS_PATH="$(pvm_alias_path)"
  mkdir -p "${ALIAS_PATH}"
  
  pvm_echo "${RESOLVED_VERSION}" > "${ALIAS_PATH}/${ALIAS_NAME}"
  pvm_echo "Alias '${ALIAS_NAME}' set to version ${RESOLVED_VERSION}"
}

pvm_unalias() {
  local ALIAS_NAME
  ALIAS_NAME="${1}"
  
  if [ -z "${ALIAS_NAME}" ]; then
    pvm_err "Usage: pvm unalias <name>"
    return 1
  fi
  
  local ALIAS_PATH
  ALIAS_PATH="$(pvm_alias_path)"
  local ALIAS_FILE="${ALIAS_PATH}/${ALIAS_NAME}"
  
  if [ ! -f "${ALIAS_FILE}" ]; then
    pvm_err "Alias '${ALIAS_NAME}' does not exist."
    return 1
  fi
  
  rm -f "${ALIAS_FILE}"
  pvm_echo "Alias '${ALIAS_NAME}' has been removed."
}

pvm_global() {
  local ARG
  ARG="${1}"

  local ALIAS_PATH
  ALIAS_PATH="$(pvm_alias_path)"
  mkdir -p "${ALIAS_PATH}"

  if [ -z "${ARG}" ]; then
    if [ -f "${ALIAS_PATH}/default" ]; then
      pvm_echo "$(cat "${ALIAS_PATH}/default")"
      return 0
    fi
    pvm_err "No global version set. Use 'pvm global <version>'."
    return 1
  fi

  if [ "${ARG}" = "--unset" ] || [ "${ARG}" = "unset" ]; then
    rm -f "${ALIAS_PATH}/default"
    pvm_echo "Global CocoaPods version unset."
    return 0
  fi

  local RESOLVED
  # Support 'latest' keyword
  if [ "${ARG}" = "latest" ]; then
    RESOLVED="$(pvm_version_remote "${ARG}")"
  else
    RESOLVED="$(pvm_version "${ARG}")"
  fi

  pvm_echo "${RESOLVED}" > "${ALIAS_PATH}/default"
  pvm_echo "Global CocoaPods version set to ${RESOLVED}"

  # Try to apply to current session if installed
  if pvm_ensure_version_installed "${RESOLVED}"; then
    pvm_use "${RESOLVED}"
  else
    pvm_err "Version ${RESOLVED} is not installed. Run 'pvm install ${RESOLVED}'."
  fi
}

pvm_which() {
  local VERSION
  VERSION="${1}"
  
  if [ -z "${VERSION}" ]; then
    VERSION="$(pvm_ls_current)"
  fi
  
  if [ "${VERSION}" = "none" ]; then
    pvm_err "No version is currently active."
    return 1
  fi
  
  # Resolve version
  local RESOLVED_VERSION
  RESOLVED_VERSION="$(pvm_version "${VERSION}")"
  
  local VERSION_PATH
  VERSION_PATH="$(pvm_version_path "${RESOLVED_VERSION}")"
  
  if [ ! -d "${VERSION_PATH}" ]; then
    pvm_err "Version ${RESOLVED_VERSION} is not installed."
    return 1
  fi
  
  pvm_echo "${VERSION_PATH}/bin/pod"
}

pvm() {
  if [ $# -lt 1 ]; then
    pvm --help
    return
  fi

  local COMMAND
  COMMAND="${1}"
  shift

  case $COMMAND in
    "help" | "--help" | "-h")
      pvm_echo "Pod Version Manager (pvm)"
      pvm_echo ""
      pvm_echo "Usage:"
      pvm_echo "  pvm install <version>       Install a specific version of CocoaPods"
      pvm_echo "  pvm use <version>           Use a specific version of CocoaPods"
      pvm_echo "  pvm use system              Use system-wide CocoaPods"
      pvm_echo "  pvm ls                      List installed versions"
      pvm_echo "  pvm ls-remote               List available versions"
      pvm_echo "  pvm uninstall <version>     Uninstall a specific version"
      pvm_echo "  pvm current                 Display currently active version"
      pvm_echo "  pvm global [version]        Set or show global CocoaPods version"
      pvm_echo "  pvm alias <name> <version>  Set an alias for a version"
      pvm_echo "  pvm unalias <name>          Remove an alias"
      pvm_echo "  pvm which [version]         Display path to pod binary"
      pvm_echo "  pvm unload                  Unload pvm and use system pod"
      pvm_echo "  pvm --help                  Show this help message"
      pvm_echo ""
      pvm_echo "Examples:"
      pvm_echo "  pvm install 1.12.0          Install CocoaPods 1.12.0"
      pvm_echo "  pvm install latest          Install the latest version"
      pvm_echo "  pvm use 1.12.0              Switch to CocoaPods 1.12.0"
      pvm_echo "  pvm alias stable 1.12.0     Create alias 'stable' for 1.12.0"
      pvm_echo "  pvm use stable              Use the 'stable' alias"
      pvm_echo "  pvm global 1.16.2           Set 1.16.2 as global default"
      pvm_echo "  pvm global --unset          Unset global default"
      pvm_echo ""
      pvm_echo "Environment Variables:"
      pvm_echo "  PVM_DIR                     pvm installation directory (default: ~/.pvm)"
      pvm_echo "  PVM_RUBY_MIRROR             RubyGems mirror URL for faster downloads"
      ;;
    "install")
      pvm_install "$@"
      ;;
    "use")
      pvm_use "$@"
      ;;
    "global")
      pvm_global "$@"
      ;;
    "ls")
      pvm_ls
      ;;
    "ls-remote")
      pvm_ls_remote
      ;;
    "uninstall")
      pvm_uninstall "$@"
      ;;
    "current")
      pvm_current
      ;;
    "alias")
      pvm_alias "$@"
      ;;
    "unalias")
      pvm_unalias "$@"
      ;;
    "which")
      pvm_which "$@"
      ;;
    "unload" | "system")
      pvm_unload
      ;;
    *)
      pvm_err "Unknown command: ${COMMAND}"
      pvm_err "Run 'pvm --help' for usage information."
      return 1
      ;;
  esac
}

# Auto-detect pvm directory
if [ -z "${PVM_DIR-}" ]; then
  PVM_DIR="$(pvm_default_install_dir)"
fi

# Create necessary directories
mkdir -p "${PVM_DIR}/versions/cocoapods"
mkdir -p "${PVM_DIR}/alias"

# Auto-use global default if set
DEFAULT_FILE="${PVM_DIR}/alias/default"
if [ -z "${PVM_COCOAPODS_VERSION-}" ] && [ -f "${DEFAULT_FILE}" ]; then
  DEFAULT_VERSION="$(cat "${DEFAULT_FILE}")"
  # Try to install default version if missing? No, that might be too aggressive on shell load.
  # Just try to use it if installed.
  
  # We manually check directory existence to avoid printing errors during shell init
  DEFAULT_VERSION_PATH="${PVM_DIR}/versions/cocoapods/${DEFAULT_VERSION}"
  if [ -d "${DEFAULT_VERSION_PATH}" ]; then
    pvm_use "${DEFAULT_VERSION}" >/dev/null 2>&1 || true
  fi
fi

pvm_echo "pvm (Pod Version Manager) loaded"

} # this ensures the entire script is downloaded #
