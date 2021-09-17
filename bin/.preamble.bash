# Include core command line parsing support, common settings and
# utility functions.
# shellcheck source=./.core_preamble.bash
source "${METADATATOOLS_HOME}/.core_preamble.bash"


# Define constants for known repo-kinds
#
# shellcheck disable=SC2034
declare APP_REPO="app"
# shellcheck disable=SC2034
declare INF_REPO="interface"
# shellcheck disable=SC2034
declare LIB_REPO="library"
# shellcheck disable=SC2034
declare PLG_REPO="plugin"
# shellcheck disable=SC2034
declare DTA_REPO="data"
# shellcheck disable=SC2034
declare TOL_REPO="tool"

# shellcheck disable=SC2034
declare GENERATED="Generated"


function _frija_locate_frija_home()
{
    # Will eventually hold the name of the folder containing _FRIJA_FOLDER_NAME
    _FRIJA_HOME="${PWD}"

    local candidate="${_FRIJA_HOME}/${_FRIJA_FOLDER_NAME}"
    # Now search for the folder containing _FRIJA_FOLDER_NAME
    while [[ "${_FRIJA_HOME}" != "" && ! -d "${candidate}" ]];
    do
        _FRIJA_HOME="${_FRIJA_HOME%/*}"
        candidate="${_FRIJA_HOME}/${_FRIJA_FOLDER_NAME}"
    done

    if [[ -z "${_FRIJA_HOME}" ]]; then
        cat <<EOF

Unable to locate folder containing ${_FRIJA_FOLDER_NAME}, that is the
base folder where repo list file(s) are found and corresponding repos
are cloned. Please use command 'frija init' to create such a folder
and then clone your repos into that folder using command 'frija clone'.

Once you have done this, please try this command ('${_FRIJA_PROGRAM_NAME}')
again.
EOF
        if [[ -n "${_FRIJA_IS_SOURCED}" ]]; then
            return 7
        else
            exit 7
        fi
    fi

    _FRIJA_FOLDER_PATH="${_FRIJA_HOME}/${_FRIJA_FOLDER_NAME}"
    # shellcheck disable=SC2034
    _FRIJA_JIRA="${_FRIJA_HOME##*/}"
}


if [[ -n "${_FRIJA_IS_SOURCED}" ]]; then
    # Top level script is sourced
    return
fi


################################################################################
# Below this point it is safe to for instance call exit; above it
# would cause the users shell to exit if we are sourced...
