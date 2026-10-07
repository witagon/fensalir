if [[ -z "${_FRIJA_DEVELOPMENT_DOMAIN}" ]]; then
    message="Variable _FRIJA_DEVELOPMENT_DOMAIN must be set before this file "
    message+="(${BASH_SOURCE[0]}) can be sourced, aborting."
    print_error "${message}" _FRIJA_EXIT_INTERNAL_ERROR
fi

if [[ -z "${_FENSALIR_CURRENT_OS}" ]]; then
    source \
	"${_FENSALIR_ROOT}/config/userfiles/scripts/fensalir-identify-os.bash"

    if [[ -z "${_FENSALIR_CURRENT_OS}" ]]; then
	print_error "Failed to detect current operating system, aborting." \
		    _FRIJA_EXIT_OTHER_PROBLEM
    fi
fi


# PWA == Personal Work Area
# This variable holds the *nix-like path to users private PWA folder
declare PWA=""

# This variable holds the OS-specific path to users private PWA folder
declare _FENSALIR_OS_PWA=""


# Use indirect reference (nameref) to associative array for OS
# $_FENSALIR_CURRENT_OS containing PWA mapping top serach path per
# domain.
_FENSALIR_PWA_MAP_NAME=$(_fensalir_pwa_map_array_name "${_FENSALIR_CURRENT_OS}")
declare -n _FENSALIR_PWA_MAP_REF="${_FENSALIR_PWA_MAP_NAME}"


if [[ -z $(_frija_array_empty "_FENSALIR_PWA_MAP_NAME") ]]; then
   message="Associative array "
   message+="$(_fensalir_pwa_map_array_name "${_FENSALIR_CURRENT_OS}") "
   message+="not defined, aborting.\\n"
   message+="Hint: Function import_pwa_map() should be used to initialize "
   message+="this variable."
   print_error "${message}" _FRIJA_EXIT_INTERNAL_ERROR
fi


# This variable contain OS-specific character used to separate path
# elements, for instance within $PATH. That is in Linux "/" is used
# and in Windows "\" is used.
declare _FENSALIR_OS_SEP=""

# This variable contain OS-specific path separator used between paths
# in $PATH
declare _FENSALIR_OS_PATH_SEP=""

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
            PWA="${_FENSALIR_PWA_MAP_REF[${_FRIJA_DEVELOPMENT_DOMAIN}]}"
        fi
        _FENSALIR_OS_PWA="${PWA}"
        ;;
    *)
        echo "Unknown platform '${_FENSALIR_CURRENT_OS}' ('${_unameOut}')." >&2
        echo "Aborting Fensalir initialization." >&2
        return
        ;;
esac


export _FENSALIR_OS_SEP
export _FENSALIR_OS_PATH_SEP
export PWA
export _FENSALIR_OS_PWA
