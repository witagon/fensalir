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
    CYGWIN*|MINGW*)
        OPERATING_SYSTEM="${WINDOWS_OS}"

        # The first index of the array $BASH_SOURCE is the absolute
        # path to current script. This control implicitly what we
        # assign to $PWA and $OS_PWA variables.

        # Use a string slice starting from index 0 and then pick the
        # following two characters
        PWA="${BASH_SOURCE[0]:0:2}"

        # Take second character of $PWA and append ":/" to create $OS_PWA
        OS_PWA="${PWA:1:1}:/"

        PATH="/c/program files (x86)/Microsoft Visual Studio/2019/Enterprise/MSBuild/Current/bin":$PATH
        ;;
    *)
        echo "Unknown platform '${_unameOut}'." >&2
        echo "Aborting Frija initialization." >&2
        return
        ;;
esac

export OPERATING_SYSTEM
export _VOLLA_WINDOWS_OS
export _VOLLA_LINUX_OS
export PWA
export OS_PWA


# Name of metadata tools repo. It is assigned a hard coded value
# during installation.
export METADATATOOLS_REPONAME=''

# Create a path to the bin folder of the metadata tools repo from path
# to this script; we assume this script is placed in the volla folder.

# This is done by first removing the last component of $BASH_SOURCE[0]
# (name of this scipt), that is the shortest suffix matching "/*"...
METADATATOOLS_HOME="${BASH_SOURCE[0]%/*}"

# ... then we add name of the metadata tools repo plus bin folder name
# appended to it.
METADATATOOLS_HOME="${METADATATOOLS_HOME}/${METADATATOOLS_REPONAME}/bin"
export METADATATOOLS_HOME

export PATH="${METADATATOOLS_HOME}:${PATH}"

if [[ -r "${METADATATOOLS_HOME}/frija" ]]; then
    # Make frija function available
    # shellcheck disable=SC1090
    source "${METADATATOOLS_HOME}/frija"
else
    notFoundMessage="${INHIBIT_NOT_FOUND_MESSAGE:-n}"
    if [[ "${INHIBIT_NOT_FOUND_MESSAGE}" == "n" ]]; then
        echo "Could not find '${METADATATOOLS_HOME}/frija' (not sourced)!" >&2
    fi
fi
