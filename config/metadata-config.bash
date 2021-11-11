# Define ourselves :)
# shellcheck disable=SC2034
declare _CONFIG_NAME="metadata-config.bash"
declare _CONFIG_TEMPLATE_NAME="metadata-config-template.bash"

# OS variant
declare OPERATING_SYSTEM=""

declare _VOLLA_WINDOWS_OS="Windows"
declare _VOLLA_LINUX_OS="Linux"

declare WINDOWS_OS="${_VOLLA_WINDOWS_OS}"
declare LINUX_OS="${_VOLLA_LINUX_OS}"


# PWA == Personal Work Area
# This variable holds the *nix-like path to users private PWA folder
declare PWA=""

# This variable holds the OS-specific path to users private PWA folder
declare OS_PWA=""

# Detect platform we are running on and initialize OPERATING_SYSTEM,
# PWA, and OS_PWA
_unameOut="$(uname -s)"
case "${_unameOut}" in
    Linux*)
        OPERATING_SYSTEM="${LINUX_OS}"
        PWA="/p/pwa/${USER}"
        OS_PWA="${PWA}"
        ;;
    CYGWIN*)
        OPERATING_SYSTEM="${WINDOWS_OS}"

        if [[ -r "/c/volla/metadata-config.bash" ]]; then
            PWA="/c"
            OS_PWA="C:/"
        elif [[ -r "/x/volla/metadata-config.bash" ]]; then
            PWA="/x"
            OS_PWA="X:/"
        fi

        PATH="/c/program files (x86)/Microsoft Visual Studio/2019/Enterprise/MSBuild/Current/bin":$PATH
        ;;
    MINGW*)
        OPERATING_SYSTEM="${WINDOWS_OS}"

        if [[ -r "/c/volla/metadata-config.bash" ]]; then
            PWA="/c"
            OS_PWA="C:/"
        elif [[ -r "/x/volla/metadata-config.bash" ]]; then
            PWA="/x"
            OS_PWA="X:/"
        fi

        PATH="/c/program files (x86)/Microsoft Visual Studio/2019/Enterprise/MSBuild/Current/bin":$PATH
        ;;
    *)
        print_error "Unknown platform '${_unameOut}', aborting." 3
        ;;
esac

export OPERATING_SYSTEM
export _VOLLA_WINDOWS_OS
export _VOLLA_LINUX_OS
export PWA
export OS_PWA

export METADATATOOLS_HOME="${PWA}/volla/metadatatools_01/bin"
export PATH="${METADATATOOLS_HOME}:${PATH}"

if [[ -r "${METADATATOOLS_HOME}/frija" ]]; then
    # Make frija function available
    # shellcheck disable=SC1090
    source "${METADATATOOLS_HOME}/frija"
else
    echo "'${METADATATOOLS_HOME}/frija' not sourced!"
fi
