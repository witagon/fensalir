################################################################################
#  NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE  #
################################################################################
# This file is sourced from fensalir-setup.bash which is modified
# during installation. The variables $_FENSALIR_REPONAME and
# $_FENSALIR_ROOT are assumed to be configured in this file and these
# are then used in this file to configure Fensalir (Frija and Volla)
# and make them available in the environment.
################################################################################
#  NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE  #
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


# Detect platform we are running on
_unameOut="$(uname -s)"

# Adapt $_FENSALIR_ROOT depending on which platform it was installed
# on and where we are currently running. This is due to that we must
# handle non-FC Windows VDIs where Fensalir installation is shared
# between Linux and Windows...
case "${_FENSALIR_CURRENT_OS}" in
    "${_FENSALIR_LINUX}")
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
    "${_FENSALIR_SOLARIS}")
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
    "${_FENSALIR_WINDOWS}")
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
        echo "Unknown platform '${_FENSALIR_CURRENT_OS}' ('${_unameOut}')." >&2
        echo "Aborting Fensalir initialization." >&2

        # Abort script
        return
        ;;
esac


_FENSALIR_HOME="${_FENSALIR_ROOT}/bin"

# Create a path to the support folder of the Fensalir repo.
_FENSALIR_SUPPORT_NAME="support"
_FENSALIR_SUPPORT_PATH="${_FENSALIR_ROOT}/${_FENSALIR_SUPPORT_NAME}"

# Create a path to the config folder of the Fensalir repo.
_FENSALIR_CONFIG_NAME="config"
_FENSALIR_CONFIG_PATH="${_FENSALIR_ROOT}/${_FENSALIR_CONFIG_NAME}"

# Create a path to the config folder of the Fensalir repo.
_FENSALIR_GNUMAKE_NAME="gnumake"
_FENSALIR_GNUMAKE_PATH="${_FENSALIR_SUPPORT_PATH}/${_FENSALIR_GNUMAKE_NAME}"


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

export _FENSALIR_SUPPORT_NAME
export _FENSALIR_GNUMAKE_NAME
export _FENSALIR_CONFIG_NAME

export _FENSALIR_SUPPORT_PATH
export _FENSALIR_GNUMAKE_PATH
export _FENSALIR_CONFIG_PATH

# Make our updated $PATH available in sub-shells. Note that if it is
# changed after this point and the change is intended to be published
# then the variable must be re-exported for that change to take
# effect. This is true for all exported variable (any change that
# should be made available must be re-exported to take effect).
export PATH="${_FENSALIR_HOME}:${PATH}"


# This variable contain OS-specific character used to separate path
# elements, for instance within $PATH. That is in Linux "/" is used
# and in Windows "\" is used.
declare _FENSALIR_OS_SEP=""

# This variable contain OS-specific path separator used between paths
# in $PATH
declare _FENSALIR_OS_PATH_SEP=""


# PWA == Personal Work Area
# This variable holds the *nix-like path to users private PWA folder
declare PWA=""

# This variable holds the OS-specific path to users private PWA folder
declare OS_PWA=""

# Continue per platform configuration
case "${_FENSALIR_CURRENT_OS}" in
    "${_FENSALIR_LINUX}")
        _FENSALIR_OS_SEP="/"
        _FENSALIR_OS_PATH_SEP=":"

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
    "${_FENSALIR_SOLARIS}")
        _FENSALIR_OS_SEP="/"
        _FENSALIR_OS_PATH_SEP=":"

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
    "${_FENSALIR_WINDOWS}")
        # shellcheck disable=SC2034
        _FENSALIR_OS_SEP="\\"
        # shellcheck disable=SC2034
        _FENSALIR_OS_PATH_SEP=";"

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
        echo "Unknown platform '${_FENSALIR_CURRENT_OS}' ('${_unameOut}')." >&2
        echo "Aborting Fensalir initialization." >&2
        return
        ;;
esac


# We have already checked that 'frija' script exist so we hope that it
# is still the case.
export _FENSALIR_OS_SEP
export _FENSALIR_OS_PATH_SEP
export PWA
export OS_PWA

# Make fensalir function available
#
# shellcheck source=../bin/fensalir
source "${_FENSALIR_HOME}/fensalir"

# Make frija function available
#
# shellcheck source=../bin/frija
source "${_FENSALIR_HOME}/frija"
