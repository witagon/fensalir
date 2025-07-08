# This file is sourced by the frija-* scripts.


# Include core command line parsing support, common settings and
# utility functions.
# shellcheck source=./.core_preamble.bash
source "${_FENSALIR_HOME}/.core_preamble.bash"

# Include core command line option processing support functions.
# shellcheck source=./.option_parsing.bash
source "${_FENSALIR_HOME}/.option_parsing.bash"


# Define constants for known repo kinds
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


# Define constants for known repo variants
#
# shellcheck disable=SC2034
declare NRL_REPO="norepolib"


# shellcheck disable=SC2034
declare GENERATED="Generated"


# Pattern used for detecting when the current path to a PWA folder is
# the actual path and not the symlinked path ("/p/pwa/fnord" vs.
# "/p/pwa-user/7/fnord")
_FRIJA_PWA_USER_PATTERN="^/p/pwa-user/[^/]+/(.*)$"


# If current folder is either the workspace folder or a subfolder of
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
            # never occur
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
        if  (( BASH_SUBSHELL < 2 )); then
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


BRANCH_TYPE_BOTH="Both"
BRANCH_TYPE_FEATURE="Feature"
BRANCH_TYPE_SUBFEATURE="Sub-feature"

function _frija_workspace_branch_list()
{
    print_debug_enter

    local branchType="${1}"
    local completePrefix="${2:-}"

    print_debug "branchType='${branchType}'"
    print_debug "completePrefix='${completePrefix}'"

    declare -a branches=()

    _frija_locate_workspace
    print_debug "_FRIJA_WS_PATH='${_FRIJA_WS_PATH}'"
    print_debug "_FRIJA_FEATURE_ID='${_FRIJA_FEATURE_ID}'"

    if [[ -z "${_FRIJA_FEATURE_ID}" ]]; then
        local message="Current path '${PWD}' is not a Workspace or your "
        message+="Workspace is corrupt."
        _frija_completion_error_message "${message}"
        return
    fi

    local compositeList=""
    compositeList=$(_frija_read_composites "")
    print_debug "compositeList='${compositeList}'"

    if [[ -z "${compositeList}" ]]; then
        local message="Composite list configuration is empty, please run "
        message+="${BOLD}frija clone${CLEAR} or ${BOLD}frija fetch${CLEAR} "
        message+="to update composite list, aborting."
        _frija_completion_error_message "${message}"
    fi

    # Replace all sequences of comma with a single comma using
    # extended globbing.
    compositeList="${compositeList//+(,)/,}"

    # Remove any initial comma from $compositeList
    compositeList="${compositeList#,}"

    # Remove any trailing comma from $compositeList
    compositeList="${compositeList%,}"

    # Finally replace all commas with "/ " and add a trailing
    # slash to ensure that all elements in the sequence end with
    # slash.
    compositeList="${compositeList//,// }/"

    # Create new string where all characters EXCEPT commas are
    # removed from $compositeList
    local commas="${compositeList//[^,]}"
    print_debug "commas='${commas}'"
    print_debug "#commas='${#commas}'"

    if (( ${#commas} > 0 )); then
        # $compositeList is a comma-separated list, hence brace
        # expansion is needed.
        compositeList="{${compositeList}}"
    else
        compositeList="${compositeList}"
    fi

    print_debug "compositeList='${compositeList}'"
    print_debug "_FRIJA_FEATURE_ID='${_FRIJA_FEATURE_ID}"

    # Format used is "<path>:<file prefix>", that is for feature
    # branches we are looking for files starting with
    # $_FRIJA_FEATURE_ID, but for sub-feature branches we are instead
    # looking for any files in the folder $_FRIJA_FEATURE_ID .
    #
    # This string is later split into its two parts when iterating
    # over the array.
    declare -a branchPaths=()
    case "${branchType}" in
        "${BRANCH_TYPE_BOTH}")
            branchPaths=("heads/${_FRIJA_FEATURE_ID}:"
                         "heads/feature:${_FRIJA_FEATURE_ID}"
                         "remotes/origin/feature:${_FRIJA_FEATURE_ID}")
            ;;
        "${BRANCH_TYPE_FEATURE}")
            branchPaths=("heads/feature:${_FRIJA_FEATURE_ID}"
                         "remotes/origin/feature:${_FRIJA_FEATURE_ID}")
            ;;
        "${BRANCH_TYPE_SUBFEATURE}")
            branchPaths=("heads/${_FRIJA_FEATURE_ID}:")
            ;;
    esac
    print_debug_array "branchPaths"

    declare -a files=()
    declare -A filteredBranches=()
    for currentBranchPath in "${branchPaths[@]}"; do
        print_debug "Processing currentBranchPath='${currentBranchPath}'"
        local pathPrefix="${_FRIJA_WS_PATH}/${compositeList}*/"
        local gitPrefix=".git/refs/${currentBranchPath%:*}"
        local branchNamePrefix="${currentBranchPath#*:}${completePrefix}"

        print_debug "currentBranchPath%:*='${currentBranchPath%:*}'"
        print_debug "currentBranchPath#*:='${currentBranchPath#*:}'"
        print_debug "pathPrefix='${pathPrefix}'"
        print_debug "gitPrefix='${gitPrefix}'"
        print_debug "branchNamePrefix='${branchNamePrefix}'"

        print_debug "-----"
        print_debug "Calling frija_list_files"
        print_debug "Argument #2: '${pathPrefix}${gitPrefix}'"
        print_debug "Argument #4: '${branchNamePrefix}'"
        frija_list_files files \
                         "${pathPrefix}${gitPrefix}" \
                         "" \
                         "${branchNamePrefix}" \
                         "" \
                         "" \
                         "${FILE_FILTER}"
        print_debug "Returned from frija_list_files"
        print_debug "Items in _FRIJA_FILE_LIST=${#_FRIJA_FILE_LIST[@]}"
        if (( ${#_FRIJA_FILE_LIST[@]} > 0 )); then
            files=( "${_FRIJA_FILE_LIST[@]}" )
            print_debug_array "files"

            # Iterate over all found branches in all repos where repo names
            # have been removed since those are not interesting for us (part
            # before colon). Add them to an associative array as keys and the
            # value is the dummy '1'. This will effectively remove all
            # duplicates from the list we iterate over.
            for item in "${files[@]#*:}"; do
                filteredBranches["${item}"]=1
            done
        fi
    done

    if (( ${#filteredBranches[@]} > 0 )); then
        print_debug_array "filteredBranches"
        # Return list of keys in $filteredBranches as the search result.
        files=( "${!filteredBranches[@]}" )
        print_debug_array "files"

        _FRIJA_FILE_LIST=( "${files[@]}" )
    else
        _FRIJA_FILE_LIST=()
    fi

    print_debug_array "_FRIJA_FILE_LIST"
    print_debug_exit
}


function _frija_workspace_repolist()
{
    print_debug_enter ""

    local completePrefix="${1:-}"

    declare -a files=()

    _frija_locate_workspace
    print_debug "_FRIJA_WS_PATH='${_FRIJA_WS_PATH}'"

    # Get all files repos reachable from $_FRIJA_WS_PATH
    declare -a files=()


    local subPath=""
    local folderPrefix=""
    if [[ "${completePrefix}" =~ ^(([^/]+)(/[^/]*)?) ]]; then
        completePrefix="${BASH_REMATCH[1]}"
        subPath="${BASH_REMATCH[2]}"
        folderPrefix="${BASH_REMATCH[3]}"
    fi


    # When $completePrefix is an empty string
    # =>
    # Both $subPath and $folderPrefix are empty strings.
    if [[ -z "${completePrefix}" ]]; then
        local compositeList=""
        compositeList=$(_frija_read_composites "")
        print_debug "compositeList='${compositeList}'"

        if [[ -z "${compositeList}" ]]; then
            local message="Composite list configuration is empty, please run "
            message+="${BOLD}frija clone${CLEAR} or ${BOLD}frija fetch${CLEAR} "
            message+="to update composite list, aborting."
            print_error "${message}"
        fi

        # Replace all sequences of comma with a single comma using
        # extended globbing.
        compositeList="${compositeList//+(,)/,}"

        # Remove any initial comma from $compositeList
        compositeList="${compositeList#,}"

        # Remove any trailing comma from $compositeList
        compositeList="${compositeList%,}"

        # Finally replace all commas with "/ " and add a trailing
        # slash to ensure that all elements in the sequence end with
        # slash.
        compositeList="${compositeList//,// }/"

        # Create new string where all characters EXCEPT commas are
        # removed from $compositeList
        local commas="${compositeList//[^,]}"
        print_debug "commas='${commas}'"
        print_debug "#commas='${#commas}'"

        if (( ${#commas} > 0 )); then
            # $compositeList is a comma-separated list, hence brace
            # expansion is needed.
            subPath="{${compositeList}}"
        else
            subPath="${compositeList}"
        fi
    fi

    # Assuming $completePrefix is one of "foo/bar" or "foo/" or "foo"
    # gives transformation of $subPath and $folderPrefix according to
    # table below
    #
    # $subPath  $folderPrefix   =>   $subPath  $folderPrefix
    #   "foo"      "/bar"              "foo/"     "bar*/"
    #   "foo"      "/"                 "foo/"     "*/"
    #   "foo"      ""                  "foo/"     "*/"

    subPath+="/"
    folderPrefix="${folderPrefix#/}*/"

    # The actual completion prefix to use is then the combination of
    # $subPath and $folderPrefix.
    completePrefix="${subPath}${folderPrefix}"

    print_debug "completePrefix='${completePrefix}'"

    frija_list_files files \
                     "${_FRIJA_WS_PATH}" \
                     ""
                     "${completePrefix}" \
                     "" \
                     ".git" \
                     "" \
                     "d"

    # Remove below line when Bash 4.3 or newer is used
    files=("${_FRIJA_FILE_LIST[@]}")
    print_debug "Returned list: '${files[*]}'"

    # Remove suffix .git folder name including slash from end of each
    # item in list, that is "foo/bar/.git" --> "foo/bar"
    files=("${files[@]%/.git}")
    print_debug_array "files"

    _FRIJA_FILE_LIST=( "${files[@]}" )
    print_debug_exit ""
}


function _frija_subcommand_repo_file_list()
{
    declare -a files

    # Ensure $_FRIJA_WS_PATH is set
    _frija_locate_workspace

    # Get all repos files in $_FRIJA_WS_PATH
    frija_list_files files "${_FRIJA_WS_PATH}" "" "" "${REPO_LIST_EXTENSION}"

    if (( ${#_FRIJA_FILE_LIST[@]} > 0 )); then
        # Remove below line when Bash 4.3 or newer is used
        files=("${_FRIJA_FILE_LIST[@]}")

        # Remove suffix ${REPO_LIST_EXTENSION} from file list
        files=("${files[@]%${REPO_LIST_EXTENSION}}")

        echo "${files[@]}"
    fi
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
