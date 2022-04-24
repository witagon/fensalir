################################################################################
# Bash Version Check
#-------------------------------------------------------------------------------
# Ensure user has a compatible Bash version in path
#

# Frija expects at least this major version number of Bash
declare -i _FRIJA_BASH_MAJOR=4
export _FRIJA_BASH_MAJOR

# Frija expects at least this minor version number in combination with
# $_FRIJA_BASH_MAJOR of Bash
declare -i _FRIJA_BASH_MINOR=2
export _FRIJA_BASH_MINOR

# Pattern used for extracting major and minor Bash versions.
_FRIJA_BASH_VERSION_PATTERN="^([0-9]+)[.]([0-9]+)[.].*"
export _FRIJA_BASH_VERSION_PATTERN

function _frija_check_bash_version()
{
    declare -i returnValue=0

    if [[ "${BASH_VERSION}" =~ ${_FRIJA_BASH_VERSION_PATTERN} ]]; then
        declare -i foundMajor="${BASH_REMATCH[1]}"
        if (( foundMajor < _FRIJA_BASH_MAJOR )); then
            returnValue=1
            cat <<EOF >&2
================================================================================
Found Bash version ${BASH_VERSION} in path whch does not meet minimum version
retquirements from Frija.

At least version ${_FRIJA_BASH_MAJOR}.${_FRIJA_BASH_MINOR} or later is required.

Aborting Frija initialization. Please ensure that a you have a Bash version
meeting above requirements in your PATH environment variable and try again.
================================================================================
EOF
        elif (( foundMajor == _FRIJA_BASH_MAJOR )); then
            declare -i foundMinor="${BASH_REMATCH[2]}"

            if (( foundMinor < _FRIJA_BASH_MINOR )); then
                returnValue=1
                cat <<EOF >&2
================================================================================
Found Bash version ${BASH_VERSION} in path whch does not meet minimum version
retquirements from Frija.

Even though this version meets the major version requirement from Frija, the
minor version does not as ${_FRIJA_BASH_MAJOR}.${_FRIJA_BASH_MINOR} or later is required.

Aborting Frija initialization. Please ensure that a you have a Bash version
meeting above requirements in your PATH environment variable and try again.
================================================================================
EOF
            fi
        fi
    else
        returnValue=1
        cat <<EOF >&2
================================================================================
Found Bash version ${BASH_VERSION} in path whch does not meet minimum version
retquirements from Frija.

Expected a version starting with ${_FRIJA_BASH_MAJOR}.${_FRIJA_BASH_MINOR} or similar. Due to this it is not possible
to determine if found version is compatible with Bash ${_FRIJA_BASH_MAJOR}.${_FRIJA_BASH_MINOR} or not.

Aborting Frija initialization. Please ensure that a you have a Bash version
meeting above requirements in your PATH environment variable and try again.
================================================================================
EOF
    fi

    return $returnValue
}

if ! _frija_check_bash_version; then
    # Too old Bash version found in path, no point in continuing with
    # the setup
    return
fi

# Make function available in sub-shells
export -f _frija_check_bash_version

#
########################## End Of Bash Version Check ###########################


# Name of subsystem repo tools repo. It is assigned a hard coded value
# during installation.
export REPO_TOOLS_REPONAME="${_REPO_NAME}"

# Create a path to the bin folder of the Fensalir repo from path
# to this script.

# This variable is assigned a hard coded value during installation.
REPO_TOOLS_HOME="${_REPO_PATH%/*}"

# Detect platform we are running on and initialize OPERATING_SYSTEM,
# PWA, and OS_PWA
_unameOut="$(uname -s)"

# Adapt $REPO_TOOLS_HOME depending on which platform it was installed
# on and where we are currently running. This is due to that we must
# handle non-FC Windows VDIs where Fensalir installation is shared
# between Linux and Windows...
case "${_unameOut}" in
    Linux*)
        # In case Frija has been installed on X: from Windows and we
        # are on then we will get sourced with a Cygwin path to frija.
        # Below string substitution adapts the path so it will work in
        # this context. That is the substring "/x/volla" is replaced by
        # "/p/pwa/$USER/volla".
        #
        # Note that if there is no match then $REPO_TOOLS_HOME will
        # not be changed.
        REPO_TOOLS_HOME=${REPO_TOOLS_HOME/\/x\/volla//p/pwa/${USER}/volla}
        ;;
    SunOS*)
        # In case Frija has been installed on X: from Windows and we
        # are on then we will get sourced with a Cygwin path to frija.
        # Below string substitution adapts the path so it will work in
        # this context. That is the substring "/x/volla" is replaced by
        # "/p/pwa/$USER/volla".
        #
        # Note that if there is no match then $REPO_TOOLS_HOME will
        # not be changed.
        REPO_TOOLS_HOME=${REPO_TOOLS_HOME/\/x\/volla//p/pwa/${USER}/volla}
        ;;
    CYGWIN*|MINGW*)
        # In case Frija has been installed on Linux and we are on
        # Windows and C: is not a "local" drive then we will get a
        # Linux path to Fensalir which will not work. Below string
        # substitution adapts the path so it will work in this context
        # if that is the case. That is the substring "p/pwa" is
        # replaced by "x".
        #
        # Note that if there is no match then $REPO_TOOLS_HOME will
        # not be changed.
        REPO_TOOLS_HOME=${REPO_TOOLS_HOME/\/p\/pwa\/${USERNAME}//x}
        ;;
    *)
        echo "Unknown platform '${_unameOut}'." >&2
        echo "Aborting Fensalir initialization." >&2
        return
        ;;
esac


# ... then we add name of the Fensalir repo plus bin folder name
# appended to it.
export REPO_TOOLS_HOME="${REPO_TOOLS_HOME}/${REPO_TOOLS_REPONAME}/bin"

# $PATH is exported below
PATH="${REPO_TOOLS_HOME}:${PATH}"


# Create a path to the config folder of the Fensalir repo.
REPO_TOOLS_CONFIG_PATH="${REPO_TOOLS_HOME%/*}/config"
export REPO_TOOLS_CONFIG_PATH

# Define where we are located. These settings affect things like tag
# names created using 'frija tag' command. It can also affects which
# commit you see in Fensalir-, locale-, and subsystem-repos when
# selecting release or development branches in those repos using the
# corresponding frija commands.
#
# These variables are assigned hard coded values during installation.
export _FRIJA_DEVELOPMENT_COUNTRY=''
export _FRIJA_DEVELOPMENT_SITE=''
export _FRIJA_DEVELOPMENT_DOMAIN=''


# OS variant
declare OPERATING_SYSTEM=""

# This variable contain OS-specific character used to separate path
# elements, for instance within $PATH. That is in Linux "/" is used
# and in Windows "\" is used.
declare OS_SEPARATOR=""

# This variable contain OS-specific path separator used between paths
# in $PATH
declare OS_PATH_SEPARATOR=""

# This variable contain build Bash environment-specific path separator
# used between paths in $PATH
#
# shellcheck disable=SC2034
export PATH_SEPARATOR=":"

export _VOLLA_WINDOWS_OS="Windows"
export _VOLLA_LINUX_OS="Linux"

# TODO: Remove after build, clone, generate, ... has been updated to
# use _VOLLA_-variants instead.
export WINDOWS_OS="${_VOLLA_WINDOWS_OS}"
export LINUX_OS="${_VOLLA_LINUX_OS}"


# PWA == Personal Work Area
# This variable holds the *nix-like path to users private PWA folder
declare PWA=""

# This variable holds the OS-specific path to users private PWA folder
declare OS_PWA=""

# Continue per platform configuration
case "${_unameOut}" in
    Linux*)
        OPERATING_SYSTEM="${LINUX_OS}"
        OS_SEPARATOR="/"
        OS_PATH_SEPARATOR=":"

        PWA="/p/pwa/${USER}"
        OS_PWA="${PWA}"
        ;;
    SunOS*)
        OPERATING_SYSTEM="${LINUX_OS}"
        OS_SEPARATOR="/"
        OS_PATH_SEPARATOR=":"

        PWA="/p/pwa/${USER}"
        OS_PWA="${PWA}"
        ;;
    CYGWIN*|MINGW*)
        OPERATING_SYSTEM="${WINDOWS_OS}"
        # shellcheck disable=SC2034
        OS_SEPARATOR="\\"
        # shellcheck disable=SC2034
        OS_PATH_SEPARATOR=";"

        # The first index of the array $BASH_SOURCE is the absolute
        # path to current script. This control implicitly what we
        # assign to $PWA and $OS_PWA variables.

        # Use a string slice starting from index 0 and then pick the
        # following two characters
        PWA="${BASH_SOURCE[0]:0:2}"

        # Take second character of $PWA and append ":/" to create $OS_PWA
        OS_PWA="${PWA:1:1}:/"

        # TODO: To be removed as this configuration does not belong here.
        PATH="/c/program files (x86)/Microsoft Visual Studio/2019/Enterprise/MSBuild/Current/bin":$PATH
        ;;
    *)
        echo "Unknown platform '${_unameOut}'." >&2
        echo "Aborting Fensalir initialization." >&2
        return
        ;;
esac

export OPERATING_SYSTEM
export OS_SEPARATOR
export OS_PATH_SEPARATOR
export PWA
export OS_PWA

# Here we can safely export $PATH
export PATH

if [[ -r "${REPO_TOOLS_HOME}/frija" ]]; then
    # Make frija function available
    # shellcheck disable=SC1090
    source "${REPO_TOOLS_HOME}/frija"
else
    notFoundMessage="${INHIBIT_NOT_FOUND_MESSAGE:-n}"
    if [[ "${notFoundMessage}" == "n" ]]; then
        echo "Could not find '${REPO_TOOLS_HOME}/frija' (not sourced)!" >&2
        echo "This means that there is NO frija command available." >&2
    fi
fi
