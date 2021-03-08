# Include core command line parsing support, common settings and
# utility functions.
# shellcheck source=./.core_preamble.bash
source "${PROGRAM_DIR}/.core_preamble.bash"

function locate_frija_home()
{
    # Will eventually hold the name of the folder containing FRIJA_FOLDER_NAME
    FRIJA_HOME="${PWD}"

    echo "FRIJA_HOME: ${FRIJA_HOME}"
    # Now search for the folder containing FRIJA_FOLDER_NAME
    while [[ "${FRIJA_HOME}" != "" && ! -d "${FRIJA_HOME}/${FRIJA_FOLDER_NAME}" ]];
    do
        FRIJA_HOME="${FRIJA_HOME%/*}"
        echo "FRIJA_HOME: ${FRIJA_HOME}"
    done

    if [[ -z "${FRIJA_HOME}" ]]; then
        cat <<EOF

Unable to locate folder containing ${FRIJA_FOLDER_NAME}, that is the
base folder where repo list file(s) are found and corresponding repos
are cloned. Please use command 'frija init' to create such a folder
and then clone your repos into that folder using command 'frija clone'.

Once you have done this, please try this command ('${PROGRAM_NAME}') again
from ${FRIJA_HOME} or a sub-folder.
EOF
        exit
    fi
}

cd "${FRIJA_HOME}"
