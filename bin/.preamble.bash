# This file is sourced by the frija-* scripts.


# Include core command line parsing support, common settings and
# utility functions.
# shellcheck source=./.core_preamble.bash
source "${_FENSALIR_HOME}/.core_preamble.bash"


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
declare VOL_REPO="volla"
# shellcheck disable=SC2034
declare BEV_REPO="buildenv"
# shellcheck disable=SC2034
declare FEN_REPO="fensalir"

# shellcheck disable=SC2034
declare GENERATED="Generated"


function _frija_completion_help_message()
{
    local helpMessage="${1}"

    # Prefix help message with name of frija command (in bold)
    local message="${BASH_SOURCE[1]##*/}"
    message="${BOLD}${message/-/ }:${CLEAR} ${helpMessage}"

    _frija_echo ""
    _frija_echo ""
    _frija_redraw_current_line
    _frija_echo "${message}"
}


function _frija_completion_note_message()
{
    local noteMessage="${1}"

    # Prefix note message with name of frija command (in bold)
    local message="${BASH_SOURCE[1]##*/}"
    message="${BOLD}${message/-/ }: ${UNDERLINE_ON}Note${CLEAR}: "
    message+="${noteMessage}"

    _frija_echo ""
    _frija_echo ""
    _frija_redraw_current_line
    _frija_echo "${message}"
}


function _frija_completion_warning_message()
{
    local warningMessage="${1}"

    # Prefix warning message with name of frija command (in bold)
    local message="${BASH_SOURCE[1]##*/}"
    message="${BOLD}${message/-/ }: ${UNDERLINE_ON}WARNING${CLEAR}: "
    message+="${warningMessage}"

    _frija_echo ""
    _frija_echo ""
    _frija_redraw_current_line
    _frija_echo "${message}"
}


function _frija_completion_error_message()
{
    local errorMessage="${1}"

    # Prefix error message with name of frija command (in bold)
    local message="${BASH_SOURCE[1]##*/}"
    message="${BOLD}${message/-/ }: ${UNDERLINE_ON}ERROR${CLEAR}: "
    message+="${errorMessage}"

    _frija_echo ""
    _frija_echo ""
    _frija_redraw_current_line
    _frija_echo "${message}"
}


# Pattern used for detecting when the current path to a PWA folder is
# the actual path and not the symlinked path ("/p/pwa/fnord" vs.
# "/p/pwa-user/7/fnord")
_FRIJA_PWA_USER_PATTERN="^/p/pwa-user/[^/]+/(.*)$"


# If current folder is wither the workspace folder or a subfolder of
# the workspace folder, then the function returns path to the
# workspace folder. Otherwise an informative error message is printed
# to the terminal, unless "leniency" is set to $LENIENT_SENSITIVITY.
#
# First parameter is optional "leniency" setting overriding default
#                    value ($STRICT_SENSITIVITY)
function _frija_locate_workspace()
{
    # Set default leniency to "strict" meaning that you get an error
    # message if current working directory ($PWD) is not within a
    # workspace folder tree.
    local leniency="${1:-${STRICT_SENSITIVITY}}"

    if ! _frija_check_bash_version; then
        # Too old Bash version found in path, no point in continuing
        print_error "" $_FRIJA_EXIT_OTHER_PROBLEM
    fi

    # Will eventually hold the name of the folder containing
    # _FRIJA_CONFIG_FOLDER_NAME
    _FRIJA_WS_PATH="${PWD}"

    # If within PWA then any non-symlink in PWA folder path is
    # replaced with the symlink we are supposed to use
    _FRIJA_PWD="${PWD}"

    local candidate="${_FRIJA_WS_PATH}/${_FRIJA_CONFIG_FOLDER_NAME}"
    # Now search for the folder containing _FRIJA_CONFIG_FOLDER_NAME
    while [[ "${_FRIJA_WS_PATH}" != "" && ! -d "${candidate}" ]];
    do
        _FRIJA_WS_PATH="${_FRIJA_WS_PATH%/*}"
        candidate="${_FRIJA_WS_PATH}/${_FRIJA_CONFIG_FOLDER_NAME}"
    done

    if [[ -n "${_FRIJA_WS_PATH}" ]]; then
        if [[ "${_FRIJA_WS_PATH}" =~ ${_FRIJA_PWA_USER_PATTERN} ]]; then
            # If Workspace is placed on the PWA then the current
            # working directory might be the one without symlink and
            # we need to convert back to a symlink-based path. This is
            # simply done by replacing "/p/pwa-user/NNN/" (where "NNN"
            # is for instance a number) with "/p/pwa/".
            _FRIJA_WS_PATH="/p/pwa/${BASH_REMATCH[1]}"

            # Due to the same reason the Frija scripts can not rely
            # directly on $PWD. However we do know that
            # $PWD/$_FRIJA_PWD matches the regexp so there is no need
            # to handle the case when there is no match as that will
            # never occurr
            [[ "${_FRIJA_PWD}" =~ ${_FRIJA_PWA_USER_PATTERN} ]]
            _FRIJA_PWD="/p/pwa/${BASH_REMATCH[1]}"
        fi

        # Read branch strategy configuration
        read -r _FRIJA_DEFAULT_BRANCH _FRIJA_BRANCH_STRATEGY rest \
             < "${candidate}/${_FRIJA_WS_BRANCH_STRATEGY_FILE}"
        _FRIJA_DEFAULT_BRANCH="${_FRIJA_DEFAULT_BRANCH//$'\r'}"
        _FRIJA_BRANCH_STRATEGY="${_FRIJA_BRANCH_STRATEGY//$'\r'}"

        case "${_FRIJA_DEFAULT_BRANCH}" in
            "${_FRIJA_FEATURE}")
                # Set $_FRIJA_FEATURE_ID to what is configured
                _FRIJA_FEATURE_ID="${_FRIJA_BRANCH_STRATEGY}"
            ;;
            "${_FRIJA_DEVELOP}")
                # Ensure $_FRIJA_FEATURE_ID is an empty string
                _FRIJA_FEATURE_ID=""
            ;;
            "${_FRIJA_RELEASE}")
                # Ensure $_FRIJA_FEATURE_ID is an empty string
                #
                # shellcheck disable=SC2034
                _FRIJA_FEATURE_ID=""
            ;;
            "")
                local message="Workspace '${_FRIJA_WS_PATH}' is corrupt; "
                message+="no default branch strategy configured. Either "
                message+="create a new workspace or try to fix the problem in "
                message+="workspace '${_FRIJA_WS_PATH}', aborting."

                print_error "${message}" $_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS
                ;;
            *)
                local message="Workspace '${_FRIJA_WS_PATH}' is corrupt; "
                message+="unrecognized branch strategy "
                message+="'${_FRIJA_BRANCH_STRATEGY}' configured, aborting."

                print_error "${message}" $_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS
                ;;
        esac
    elif [[ "${leniency}" == "${STRICT_SENSITIVITY}" ]]; then
        print_message
        print_separator
        print_message "Current folder path is not within a workspace"
        print_message "${BOLD}'${_FRIJA_PWD}'${CLEAR}"
        print_separator
        print_message
        print_message "Please switch to a workspace folder and try again."
        print_message

        local message="Command ${BOLD}frija workspace${CLEAR} is used for "
        message+="creating such folders, and ${BOLD}frija --switch=...${CLEAR} "
        message+="is used for switching to and between them."

        print_note "${message}"
        print_message

        if [[ ! -v COMP_TYPE ]]; then
            print_message
            message="Once you have either done this and/or checked the current "
            message+="folder path, please try this command "
            message+="('${_FRIJA_PROGRAM_NAME}') again."

            print_message "${message}"
        fi

        local message="Unable to locate workspace root folder, that is the "
        message+="base folder where repo list file(s) are found and "
        message+="corresponding repos are cloned."

        print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
    fi

    _FRIJA_CONFIG_FOLDER_PATH="${_FRIJA_WS_PATH}/${_FRIJA_CONFIG_FOLDER_NAME}"

    _FRIJA_CONFIG_CACHE_PATH="${_FRIJA_CONFIG_FOLDER_PATH}"
    _FRIJA_CONFIG_CACHE_PATH+="/${_FRIJA_CONFIG_CACHE_FOLDER_NAME}"
}


function _frija_workspace_repolist()
{
    declare -a files

    _frija_locate_workspace

    # Get all files repos reachable from $_FRIJA_WS_PATH
    declare -a files
    frija_list_files files "${_FRIJA_WS_PATH}" "*/**/" ".git" "d"

    # Remove below line when Bash 4.3 or newer is used
    files=("${_FRIJA_FILE_LIST[@]}")

    # Remove suffix .git folder name including slash from end of each
    # item in list, that is "foo/bar/.git" --> "foo/bar"
    files=("${files[@]%/.git}")

    echo "${files[@]}"
}


function _frija_subcommand_repo_file_list()
{
    declare -a files

    # Ensure $_FRIJA_WS_PATH is set
    _frija_locate_workspace

    # Get all repos files in $_FRIJA_WS_PATH
    frija_list_files files "${_FRIJA_WS_PATH}" "" "${REPO_LIST_EXTENSION}"

    # Remove below line when Bash 4.3 or newer is used
    files=("${_FRIJA_FILE_LIST[@]}")

    # Remove suffix ${REPO_LIST_EXTENSION} from file list
    files=("${files[@]%${REPO_LIST_EXTENSION}}")

    echo "${files[@]}"
}


# TODO: Add '_frija_' prefix to function name
function auto_locate_repo_file()
{
#    DEBUG="y"
    print_debug_enter

    # Due to that <<< hides exit code from a function call the result
    # must be stored in an intermediate variable that is then parsed
    # using read and <<< redirection (here document variation).
    #
    # In order to detect if any non-zero exit code is returned from
    # the function call we have to check $PIPESTATUS[0]. If it is
    # nonzero then we just exit with the returned exit code assuming
    # that the call printed an appropriate error message.
    #local repoFileListResult=""
    repoFileListResult="$(_frija_subcommand_repo_file_list)"

    # Check if we can auto-expand the repo-list filename; this is when
    # there is only a single repo list file in the workspace folder
    # which is the most common case
    declare -a repoFileList=()
    read -ra repoFileList <<< "${repoFileListResult}"

    # If only a single repo-list file is found, use it. Otherwise user
    # must explicitly choose which one to use
    if (( "${#repoFileList[@]}" == 1 )); then
        echo "${repoFileList[0]}"
    fi
    print_debug_exit
}


if [[ -n "${_FRIJA_IS_SOURCED}" ]]; then
    # Top level script is sourced
    return
fi


################################################################################
# Below this point it is safe to for instance call exit; above it
# would cause the users shell to exit if we are sourced...
