################################################################################
#  NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE  #
################################################################################
# This file is sourced from fensalir-init.bash which is modified
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
declare -i _FRIJA_BASH_MINOR=3
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
    # the Fensalir initialization
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


# Name of file containing mapping to PWA folder per OS and domain.
declare _FENSALIR_PWA_MAPPING_FILE_NAME="fensalir_PWA_mapping_file"

# Path to file containing mapping to PWA folder per OS and domain.
declare _FENSALIR_PWA_MAPPING_PATH="${_FENSALIR_CONFIG_PATH}"
_FENSALIR_PWA_MAPPING_PATH+="/${_FENSALIR_PWA_MAPPING_FILE_NAME}"


# Get the very basic support functions and varibles like print_message
# and print_error as well as definition of bold, italic, etc. escape
# sequences and so on.
source "${_FENSALIR_HOME}/.basic_functions.bash"


# Return name of global associative array containing map between
# domain name and PWA path for the given OS using "Linux-notation".
#
# Note! The named associative array may or may not yet exist.
function _fensalir_pwa_map_array_name()
{
    local os="${1}"

    echo "_FENSALIR_${os^^}_PWA_MAP"
}


# Return name of global associative array containing map between
# domain name and PWA path for the given OS using OS-specific
# notation.
#
# Note! The named associative array may or may not yet exist.
function _fensalir_pwa_os_map_array_name()
{
    local os="${1}"

    echo "_FENSALIR_${os^^}_OS_PWA_MAP"
}


# Read from PWA mapping file that configure per OS and domain where
# PWA is located and assign read data to created global associative
# arrays (one per OS).
#
# The name of the associative array to use for lookup is found by
# using the variable $_FENSALIR_CURRENT_OS in combination with the
# function _fensalir_pwa_map_array_name().
function _fensalir_import_pwa_map()
{
    local os=""
    local domain=""
    local mapping=""
    local osMapping=""
    local line=""
    local rest=""

    local arrayName=""

    if [[ ! -f "${_FENSALIR_PWA_MAPPING_PATH}" ]]; then
	local message="Cannot locate file '${_FENSALIR_PWA_MAPPING_FILE_NAME}'"
	message+="; expected path to file is '${_FENSALIR_PWA_MAPPING_PATH}', "
	message+="aborting."
	print_error "${message}" _FRIJA_EXIT_OTHER_PROBLEM
    fi

    declare -i lineCount=0
    while read -r line; do
	lineCount=$(( lineCount + 1 ))
	if [[ -z "${line}" ]]; then
            # Skip to next entry since it is an empty line
            continue
	fi
	
	if [[ "${line}" == "#"* ]]; then
            # Skip to next entry since it is a comment line
            continue
	else
	    read -r os domain mapping osMapping rest <<< "${line}"

	    if [[ "${os}" == "" || "${domain}" == "" || "${mapping}" == "" ]]
	    then
		local file=$(relative_path_to ${_FENSALIR_PWA_MAPPING_PATH})
		local message="${BOLD}${file}${CLEAR}:${lineCount}\\n"
		message+="'${ITALIC}${line}${CLEAR}'\\n"
		message+="All of OS ('${os}'), domain ('${domain}'), "
		message+="and mapping ('$mapping') must be assigned values, "
		message+="aborting."
		print_error "${message}" _FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS
	    fi

	    # The field 'osMapping' is optional and its default value
	    # is the mapping field.
	    if [[ -z "${osMapping}" ]]; then
		osMapping="${mapping}"
	    fi


	    # Associative array containing Linux-like paths
	    arrayName=$(_fensalir_pwa_map_array_name "${os}")

	    # Check if $arrayName not yet assigned a value (or does not
	    # yet exist)
	    if [[ ! -v "${arrayName}[@]" ]]; then
		declare -A -g "${arrayName}"
	    fi

	    # Make use of named reference introduced in Bash 4.3 to
	    # indirectly address an associative array with the name
	    # stored in $arrayName.
	    local -n reference="${arrayName}"

	    mapping="${mapping//%USER%/${USER}}"
	    reference["${domain}"]="${mapping}"

	    # Associative array containing OS-specific paths
	    arrayName=$(_fensalir_pwa_os_map_array_name "${os}")

	    # Check if $arrayName not yet assigned a value (or does not
	    # yet exist)
	    if [[ ! -v "${arrayName}[@]" ]]; then
		declare -A -g "${arrayName}"
	    fi

	    # Make use of named reference introduced in Bash 4.3 to
	    # indirectly address an associative array with the name
	    # stored in $arrayName.
	    local -n reference="${arrayName}"

	    osMapping="${osMapping//%USER%/${USER}}"
	    reference["${domain}"]="${osMapping}"
	fi
    done < "${_FENSALIR_PWA_MAPPING_PATH}"
}


# Read from PWA mapping file that configure per OS and domain where
# PWA is located and assign read data to created global associative
# arrays (one per OS).
#
# The name of the associative array to use for lookup is found by
# using the variable $_FENSALIR_CURRENT_OS in combination with the
# function _fensalir_pwa_map_array_name().
function _fensalir_print_pwa_map()
{
    local os=""
    local domain=""
    local mapping=""
    local osMapping=""
    local line=""
    local rest=""

    if [[ ! -f "${_FENSALIR_PWA_MAPPING_PATH}" ]]; then
        local message="Cannot locate file '${_FENSALIR_PWA_MAPPING_FILE_NAME}'"
        message+="; expected path to file is '${_FENSALIR_PWA_MAPPING_PATH}', "
        message+="aborting."
        print_error "${message}" _FRIJA_EXIT_OTHER_PROBLEM
    fi

    local column_gutter="     "
    local domain_field="      "
    local empty_column="${domain_field}${column_gutter}"
    local padding=""
    local row=""
    declare -i column_width=${#empty_column}
    declare -i column_rest=0
    declare -i column_padding_width=0
    print_message "Domain${column_gutter}Mapping"
    print_message "------${column_gutter// /-}-------"
    declare -i lineCount=0
    while read -r line; do
        lineCount=$(( lineCount + 1 ))
        if [[ -z "${line}" ]]; then
            # Skip to next entry since it is an empty line
            continue
        fi

        if [[ "${line}" == "#"* ]]; then
            # Skip to next entry since it is a comment line
            continue
        fi

        read -r os domain mapping osMapping rest <<< "${line}"

        if [[ "${os}" == "" || "${domain}" == "" || "${mapping}" == "" ]]
        then
            local file=$(relative_path_to ${_FENSALIR_PWA_MAPPING_PATH})
            local message="${BOLD}${file}${CLEAR}:${lineCount}\\n"
            message+="'${ITALIC}${line}${CLEAR}'\\n"
            message+="All of OS ('${os}'), domain ('${domain}'), "
            message+="and mapping ('$mapping') must be assigned values, "
            message+="aborting."
            print_error "${message}" _FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS
        fi

        if [[ "${os}" != "${_FENSALIR_CURRENT_OS}" ]]; then
            continue
        fi

        mapping="${mapping//%USER%/${USER}}"

        column_padding_width=$(( column_width - ${#domain} ))
        if (( column_padding_width < 0 )); then
            column_padding_width=1
        fi

        row="${domain}${empty_column:0:${column_padding_width}}${mapping}"

        # The field 'osMapping' is optional and its default value
        # is the mapping field.
        if [[ -n "${osMapping}" ]]; then
            osMapping="${osMapping//%USER%/${USER}}"
            row+=" --> ${osMapping}"
        fi

        print_message "${row}"
    done < "${_FENSALIR_PWA_MAPPING_PATH}"

    print_message "------${column_gutter// /-}-------"
}


# Import the PWA mapping data file and implicitly create global
# associative arrays (one per listed operating system in the file)
# that contain mapping between domain and PWA path to use.
_fensalir_import_pwa_map
