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

#
########################## End Of Bash Version Check ###########################


# Name of Fensalir repo. It is assigned a hard coded value during
# installation.
_FENSALIR_REPONAME="${_REPO_NAME}"

# Create a path to the bin folder of the Fensalir repo from path
# to this script.

# This variable is assigned a hard coded value during installation
_FENSALIR_ROOT="${_REPO_PATH}"

# Detect platform we are running on and initialize OPERATING_SYSTEM,
# PWA, and OS_PWA
_unameOut="$(uname -s)"

# Adapt $_FENSALIR_ROOT depending on which platform it was installed
# on and where we are currently running. This is due to that we must
# handle non-FC Windows VDIs where Fensalir installation is shared
# between Linux and Windows...
case "${_unameOut}" in
    Linux*)
        # In case Frija has been installed on X: from Windows and we
        # are forced to assume Linux then we will get sourced with a
        # Cygwin path to frija. Below string substitution adapts the
        # path so it will work in this context. That is the substring
        # "/x/volla" is replaced by "/p/pwa/$USER/volla".
        #
        # Note that if there is no match then $_FENSALIR_ROOT will
        # not be changed.
        _FENSALIR_ROOT=${_FENSALIR_ROOT/\/x\/volla//p/pwa/${USER}/volla}
        ;;
    SunOS*)
        # In case Frija has been installed on X: from Windows and we
        # are forced to assume SunOS then we will get sourced with a
        # Cygwin path to frija. Below string substitution adapts the
        # path so it will work in this context. That is the substring
        # "/x/volla" is replaced by "/p/pwa/$USER/volla".
        #
        # Note that if there is no match then $_FENSALIR_ROOT will
        # not be changed.
        _FENSALIR_ROOT=${_FENSALIR_ROOT/\/x\/volla//p/pwa/${USER}/volla}
        ;;
    CYGWIN*|MINGW*)
        # In case Frija has been installed on Linux and we are on
        # Windows and C: is not a "local" drive then we will get a
        # Linux path to Fensalir which will not work. Below string
        # substitution adapts the path so it will work in this context
        # if that is the case. That is the substring "p/pwa" is
        # replaced by "x".
        #
        # Note that if there is no match then $_FENSALIR_ROOT will
        # not be changed.
        _FENSALIR_ROOT=${_FENSALIR_ROOT/\/p\/pwa\/${USERNAME}//x}
        ;;
    *)
        echo "Unknown platform '${_unameOut}'." >&2
        echo "Aborting Fensalir initialization." >&2

        # Abort script
        return
        ;;
esac


_FENSALIR_HOME="${_FENSALIR_ROOT}/bin"
_FENSALIR_SUPPORT="${_FENSALIR_ROOT}/support"

# Check if we can find 'frija' script or not
if [[ ! -r "${_FENSALIR_HOME}/frija" ]]; then
    notFoundMessage="${INHIBIT_NOT_FOUND_MESSAGE:-n}"
    if [[ "${notFoundMessage}" == "n" ]]; then
        echo "Could not find '${_FENSALIR_HOME}/frija' (not sourced)!" >&2
        echo "This means that there is NO frija command available." >&2
    fi

    # Abort script
    return
fi


# Everything looks OK so continue. From this point we will affect the
# environment via calls to export. Note the variables
# $_FRIJA_BASH_MAJOR, $_FRIJA_BASH_MINOR, and
# $_FRIJA_BASH_VERSION_PATTERN have been exported above, so
# technically we have affected the environment already. It is a
# trade-off since those variables might still be useful for calling
# script.
#
# It is possible to move those exports down here if we should have no
# impact on the environment.

# Make function available in sub-shells
export -f _frija_check_bash_version

export _FENSALIR_REPONAME
export _FENSALIR_ROOT
export _FENSALIR_HOME
export _FENSALIR_SUPPORT

# Make our updated $PATH available in sub-shells. Note that if it is
# changed after this point and the change is intended to be published
# then the variable must be re-exported for that change to take
# effect. This is true for all exported variable (any change that
# should be made available must be re-exported to take effect).
export PATH="${_FENSALIR_HOME}:${PATH}"


# Create a path to the config folder of the Fensalir repo.
_FENSALIR_CONFIG_PATH="${_FENSALIR_HOME%/*}/config"
export _FENSALIR_CONFIG_PATH

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
PATH_SEPARATOR=":"

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

        if [[ -v JENKINS_HOME ]]; then
            # Script is run via Jenkins. In this case we are not
            # interested in installing Frija. Instead we want to run
            # Frija directly from within the cloned repo folder.
            PWA="${WORKSPACE}"
        else
            PWA="/p/pwa/${USER}"
        fi
        OS_PWA="${PWA}"
        ;;
    SunOS*)
        OPERATING_SYSTEM="${LINUX_OS}"
        OS_SEPARATOR="/"
        OS_PATH_SEPARATOR=":"

        if [[ -v JENKINS_HOME ]]; then
            # Script is run via Jenkins. In this case we are not
            # interested in installing Frija. Instead we want to run
            # Frija directly from within the cloned repo folder.
            PWA="${WORKSPACE}"
        else
            PWA="/p/pwa/${USER}"
        fi
        OS_PWA="${PWA}"
        ;;
    CYGWIN*|MINGW*)
        OPERATING_SYSTEM="${WINDOWS_OS}"
        # shellcheck disable=SC2034
        OS_SEPARATOR="\\"
        # shellcheck disable=SC2034
        OS_PATH_SEPARATOR=";"

        if [[ -v JENKINS_HOME ]]; then
            # Script is run via Jenkins. In this case we are not
            # interested in installing Frija. Instead we want to run
            # Frija directly from within the cloned repo folder. Note
            # that on the Windows platform $WORKSPACE contain a
            # Windows path using backspaces; below all backspaces are
            # replaced with slashes as a first step.
            OS_PWA="${WORKSPACE//\\//}"

            # Use $OS_PWA for creating PWA, that is
            # Q:/foo/bar ==> /q/foo/bar
            PWA="/${OS_PWA:0:1}"
            PWA="${PWA,,}/${OS_PWA:3}"
        else
            # The first index of the array $BASH_SOURCE is the absolute
            # path to current script. This control implicitly what we
            # assign to $PWA and $OS_PWA variables.

            if [[ "${fullclone:-}" == "" ]]; then
                # Use a string slice starting from index 0 and then pick the
                # following two characters
                PWA="${BASH_SOURCE[0]:0:2}"

                # Take second character of $PWA and append ":/" to
                # create $OS_PWA
                OS_PWA="${PWA:1:1}:/"
            else
                # Script us running on a Full Clone (FC) Windows VDI
                # machine, this means that Volla and Frija are placed
                # on C: instead of for instance X:
                PWA="/c"
                OS_PWA="c:/"
            fi
        fi
        ;;
    *)
        echo "Unknown platform '${_unameOut}'." >&2
        echo "Aborting Fensalir initialization." >&2
        return
        ;;
esac


# We have already checked that 'frija' script exist so we hope that it
# is still the case.
export OPERATING_SYSTEM
export OS_SEPARATOR
export OS_PATH_SEPARATOR
export PWA
export OS_PWA

# Make frija function available
#
# shellcheck source=../bin/frija
source "${_FENSALIR_HOME}/frija"
