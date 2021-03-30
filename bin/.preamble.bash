# Include core command line parsing support, common settings and
# utility functions.
# shellcheck source=./.core_preamble.bash
source "${METADATATOOLS_HOME}/.core_preamble.bash"


function _frija_locate_frija_home()
{
    # Will eventually hold the name of the folder containing _FRIJA_FOLDER_NAME
    _FRIJA_HOME="${PWD}"

    # Now search for the folder containing _FRIJA_FOLDER_NAME
    while [[ "${_FRIJA_HOME}" != "" && ! -d "${_FRIJA_HOME}/${_FRIJA_FOLDER_NAME}" ]];
    do
        _FRIJA_HOME="${_FRIJA_HOME%/*}"
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
}


if [[ -n "${_FRIJA_IS_SOURCED}" ]]; then
    # Top level script is sourced
    return
fi


################################################################################
# Below this point it is safe to for instance call exit; above it
# would cause the users shell to exit if we are sourced...
