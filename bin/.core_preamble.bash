# Remove longest matching prefix matching "*/", i.e. all paths up to
# but not including the program name
_FRIJA_PROGRAM_NAME="${_FRIJA_PROGRAM_PATH##*/}"

# If command is "frija-build" then _FRIJA_NAME will be "build"
_FRIJA_USAGE_NAME=${_FRIJA_PROGRAM_NAME//-/ }

# This global variable is dynamically set depending on Jira issue
# number, that is it is the path to a folder that contain
# _FRIJA_FOLDER_NAME which in turn depend on Jira issue number.
# _FRIJA_FOLDER_PATH is in turn a convenience variable that contain
# the path to _FRIJA_FOLDER_NAME.
_FRIJA_HOME=""


# Guard against this script being sourced multiple times.
#
# Note: -v tests if variable name is set or not.
if [[ -v _CORE_PREAMBLE_IS_SOURCED ]]; then
    return
fi
_CORE_PREAMBLE_IS_SOURCED="y"


# Include common configuration (global variables)
# shellcheck source=./.core_config.bash
source "${METADATATOOLS_HOME}/.core_config.bash"


# Test if _FRIJA_IS_SOURCED is *not* an empty string
# and
# if _BOOTSTRAP_PATH is unset.
#
# -v tests if variable name is set, and negating test gives instead a
# test whether variable is unset or not.
if [[ -n "${_FRIJA_IS_SOURCED}" ]] && [[ ! -v _BOOTSTRAP_PATH ]]; then
    # Top level script is sourced
    #
    # Note: This check is ONLY valid when we are not sourced from the
    # bootstrap script. Since it reuses some of the functions defined
    # in this script.
    return
fi


################################################################################
# Below this point it is safe to for instance call exit; above it
# would cause the users shell to exit if we are sourced...

# Ensure WORDY has a value
WORDY=${WORDY:-"n"}


# More safety, by turning some bugs into errors. Without 'errexit' you
# don't need ! and can replace PIPESTATUS with a simple $?, but then
# we would need to remember to explcitly test return status for each
# command. Note that ! hides the exit status of the executed command.
# Due to this we have to use PIPESTATUS to get to it.
set -o errexit -o pipefail -o noclobber -o nounset


function ensure_option_not_set()
{
    if [[ -n "${2}" ]]; then
        print_error "Multiple ${BOLD}'${1}'${CLEAR} options not allowed!" 2
    fi
}


function ensure_option_argument_set()
{
    if [[ -z "${2}" ]]; then
        print_error "${BOLD}'${1}'${CLEAR} option argument must not be an empty string." 2
    fi
}


function ensure_mode_set()
{
    declare -a target_mode_list=()
    declare -a option_list=()

    local current_mode_name="${1}"
    local current_mode="${!1}"  # Indirect parameter expansion

    # Move to next option
    shift

    local target_mode=""
    local option=""

    # Loop over argument list in installments of two arguments at a
    # time and store values in separate arrays
    while (( $# > 0 )); do
        target_mode_list+=("${1}")
        # Move to next argument
        shift

        option_list+=("${1}")
        # Move to next argument
        shift
    done

    declare -i list_length=${#target_mode_list[@]}
    if (( list_length == 0 )); then
        print_error "${BOLD}Internal error!${CLEAR} No target mode defined." 3
    fi

    if [[ -z "${current_mode}" ]]; then
        # Current mode unset; set it indirectly with first item in
        # $target_mode_list using declare and we are done
        declare -g "${current_mode_name}"="${target_mode_list[0]}"
        return;
    else
        local key
        # Iterate over the keys in $target_mode_list and check if we
        # can find a match for $current_mode
        for key in "${!target_mode_list[@]}"; do
            if [[ "${current_mode}" == "${target_mode_list[${key}]}" ]]; then
                # We have a match!
                return
            fi
        done
    fi

    # If we reach this point we were unable to find $current_mode
    # among the items in the $target_mode_list array
    if (( list_length == 1 )); then
        print_error "${BOLD}'${option}'${CLEAR} option may only be used in ${BOLD}${target_mode_list[0]}${CLEAR} mode." 2
    else
        local message=""
        declare -i last_index=$(( list_length - 1 ))
        for key in "${!target_mode_list[@]}"; do
            message+="${target_mode_list[key]}"
            if (( key < last_index )); then
                message+=", "
            fi
        done

        print_error "${BOLD}'${option}'${CLEAR} option may only be used in one of ${BOLD}${message}${CLEAR} modes." 2
    fi
}


function ensure_boolean_option_not_set()
{
    if [[ -n "${2}" ]]; then
        if [[ "${2}" != "n" ]]; then
            print_error "Multiple ${BOLD}'${1}'${CLEAR} options not allowed!" 2
        fi
    fi
}


function get_branch_name()
{
    local destination="${1}"
    local currentBranch=""

    # -C : Switch to $destination before 'git rev-parse' is executed
    currentBranch=$(git -C "${destination}" rev-parse --abbrev-ref HEAD)

    # Extract branch prefix and minimal part of label. That is, if it is
    # the main issue branch it has a format similar to
    #
    # feature/ABCD-0123_issue_title
    #
    # And if it is a sub-branch it has a format similar to
    #
    # ABCD-0123/some_label_assigned_by_developer
    #
    # The idea here is to in the former case transform the branch name to
    # something similar to "feature+ABCD-0123" and "ABCD-0123+some_label"
    declare -r ISSUE_TAG="[A-Z]+-[0-9]+"
    declare -r LABEL="[^/]+"
    declare -r PREFIX="${LABEL}"
    declare -r BRANCH_PATTERN="^(${PREFIX})/(${ISSUE_TAG}).*$"
    declare -r SUB_BRANCH_PATTERN="^(${ISSUE_TAG})/(${LABEL}).*$"

    local prefix
    local label
    if [[ "${currentBranch}" =~ ${BRANCH_PATTERN} ]]; then
        prefix="${BASH_REMATCH[1]}"
        label="${BASH_REMATCH[2]}"
        currentBranch="${label}"
    elif [[ "${currentBranch}" =~ ${SUB_BRANCH_PATTERN} ]]; then
        prefix="${BASH_REMATCH[1]}"
        label="${BASH_REMATCH[2]}"
        currentBranch="${prefix}_${label}"
    fi

    echo "${currentBranch}"
}


function print_initfile_format_doc()
{
    echo
    echo
    echo "${BOLD}Initifile file format:${CLEAR}"
    cat "$_FRIJA_PROGRAM_DIR/.initfile_format_doc.txt"
}


function print_file_format_doc()
{
    echo
    echo
    echo "${BOLD}Repo list file format:${CLEAR}"
    cat "$_FRIJA_PROGRAM_DIR/.file_format_doc.txt"
}


function print_exit_codes_doc()
{
    echo
    echo
    echo "${BOLD}Exit status:${CLEAR}"
    cat "$_FRIJA_PROGRAM_DIR/.exit_codes_doc.txt"
}


function print_error()
{
    print_newline_only_after_dot
    _frija_print_error "${@}"
}

# NOTE: Command line parsing below relies on GNU getopt which is a
# separate binary that canonicalizes the command line so it can be
# more easily parsed and sould not be confused with the Bash builtin
# getopts which does not support long options and so on.

# Ensure that we actually use GNU getopt
# - Allow command to fail with !'s side effect on errexit
# - Use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    print_error "Aborting, GNU getopt not in search path." 1
fi

# Ensure getopt is not working in compatible mode as this makes
# parsing of optional arguments virtually impossible.
unset -v GETOPT_COMPATIBLE

! _FRIJA_PARSED=$(getopt --options="${_FRIJA_SUBCOMMAND_OPTIONS}" \
                  --longoptions="${_FRIJA_SUBCOMMAND_LONGOPTS}" \
                  --name "${_FRIJA_USAGE_NAME}" \
                  -- "${@}")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # E.g. return value is 1
    #  Then getopt has complained to stdout about wrong arguments
    _frija_subcommand_usage;
    exit 2
fi

# To handle quoting correctly in output from getopt we have to do this
eval set -- "${_FRIJA_PARSED}"


function plural()
{
    local count="${1}"
    local result="s"

    if [[ "${count}" == "1" ]]; then
        result=""
    fi

    echo "${result}"
}


changeFound=""
dotPrinted=""

function print_dot()
{
    dotPrinted="y"
    echo -n "${BOLD}.${CLEAR}"
}


function print_newline_after_dot()
{
    if [[ "${WORDY}" == "n" ]]; then
        if [[ -n "${dotPrinted}" ]]; then
            dotPrinted=""
            echo ""
        fi
    else
        echo ""
    fi
}


function print_newline_only_after_dot()
{
    if [[ "${WORDY}" == "n" ]]; then
        if [[ -n "${dotPrinted}" ]]; then
            dotPrinted=""
            echo ""
        fi
    fi
}


function print_message()
{
    # Ensure given text wraps nicely to terminal width
    fold --spaces --width="${WIDTH}"<<<"${1}"
}


function print_command_error()
{
    local msg
    msg="${BOLD}Illegal combination of options;${CLEAR} ${1} may not be combined with ${2}."
    print_error "${msg}" "${3}"
}


function print_command_failure_status()
{
    local status="${1}"
    local command="${2}"

    echo "Command"
    echo "${command}"
    echo "failed with exit code ${status}, rerun with --verbose or -v."
}


function print_prefix()
{
    local value="${1}"

    if [[ "${VERBOSE}" == "n" ]]; then
        echo -n -e "${BOLD}${value}${CLEAR} "
    fi
}


function print_separator()
{
    if [[ -z "${1:-}" ]];
    then
        echo "--------------------"
    else
        echo -e "----- $1 -----"
    fi
}


function conditional_separator_print_before()
{
    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    if [[ ("${method}" == "${SINGLE}") || ("${method}" == "${FIRST}") ]]; then
        print_separator "${BOLD}${field}${CLEAR}"
    fi
}


function conditional_separator_print_after()
{
    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    if [[ "${method}" == "${SINGLE}" || "${method}" == "${LAST}" ]]; then
        print_separator "${field}"
        echo ""
    fi
}


function set_dry_run()
{
    ensure_boolean_option_not_set "Dry run" "${DRY_RUN}"
    DRY_RUN="y"
}


####
# Constants used for controlling echo behavior of run command.

# Single command with separators before and after command
SINGLE="single"

# Only separator before command
FIRST="first"

# No separator AND command echo in non-verbose mode
#
# Ignore shellcheck complaining about not used variable
# shellcheck disable=SC2034
MIDDLE="middle"

# Only separator after command
LAST="last"

# No separator and NO command echo in non-verbose mode
NONE="none"


# Copy of PIPESTATUS when a command is executed by run function.
declare -a STATUS


# As run function below but appends instead of redirects stdout to
# given destination in $3
function run_with_append()
{
    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    # If and where to redirect stdout from command
    local destination="${3}"

    # Skip first three arguments
    shift 3

    # Store rest of args in command array
    declare -a command
    local command=("${@}")


    if [[ "${VERBOSE}" == "y" ]]; then
        conditional_separator_print_before "${method}" "${field}"
        echo "${command[*]} >> ${destination}"
        STATUS=("${PIPESTATUS[@]}")

        # Execute given command, unless dry-run mode
        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}" >> "${destination}"

            # Save PIPESTATUS so we do not destroy it when for instance
            # echo something
            STATUS=("${PIPESTATUS[@]}")
        fi

        if [[ "${STATUS[0]}" -eq 0 ]]; then
            conditional_separator_print_after "${method}" "${field}"
        fi
    else
        if [[ "${method}" != "${NONE}" ]]; then
            conditional_separator_print_before "${method}" "${field}"
            echo "${command[*]}  >> ${destination}"
            STATUS=("${PIPESTATUS[@]}")
        fi

        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}" >> "${destination}" 2> /dev/null
            STATUS=("${PIPESTATUS[@]}")
            if [[ "${STATUS[0]}" -ne 0 ]]; then
                print_command_failure_status "${STATUS[0]}" "${command[*]}"
            fi
        fi

        if [[ "${method}" != "${NONE}" ]]; then
            conditional_separator_print_after "${method}" "${field}"
        fi
    fi

    return "${STATUS[0]}"
}


# As run function below but also redirects stdout to given destination in $3
function run_with_redirect()
{
    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    # If and where to redirect stdout from command
    local destination="${3}"

    # Skip first three arguments
    shift 3

    # Store rest of args in command array
    declare -a command
    local command=("${@}")


    if [[ "${VERBOSE}" == "y" ]]; then
        conditional_separator_print_before "${method}" "${field}"
        echo "${command[*]} >| ${destination}"
        STATUS=("${PIPESTATUS[@]}")

        # Execute given command, unless dry-run mode
        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}" >| "${destination}"

            # Save PIPESTATUS so we do not destroy it when for instance
            # echo something
            STATUS=("${PIPESTATUS[@]}")
        fi

        if [[ "${STATUS[0]}" -eq 0 ]]; then
            conditional_separator_print_after "${method}" "${field}"
        fi
    else
        if [[ "${method}" != "${NONE}" ]]; then
            conditional_separator_print_before "${method}" "${field}"
            echo "${command[*]}  >| ${destination}"
            STATUS=("${PIPESTATUS[@]}")
        fi

        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}" >| "${destination}" 2> /dev/null
            STATUS=("${PIPESTATUS[@]}")
            if [[ "${STATUS[0]}" -ne 0 ]]; then
                print_command_failure_status "${STATUS[0]}" "${command[*]}"
            fi
        fi

        if [[ "${method}" != "${NONE}" ]]; then
            conditional_separator_print_after "${method}" "${field}"
        fi
    fi

    return "${STATUS[0]}"
}


# Run a command in different ways:
# * If verbose mode is set to "y"
#   o Show stdout AND stderr output from command
#   o If dry-run enabled, show command line but do not execute
# * If verbose mode is set to NOT "y"
#   o If dry-run enabled, do not execute
#   o If method is _not_ NONE, echo command line
#   o Hide stdout AND stderr from command
#     - If command fails, print message to stdout
#
# Note PIPESTATUS[0] is returned, but complete PIPESTATUS is saved in
# global variable STATUS.
function run()
{
    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    # Skip first two arguments
    shift 2

    # Store rest of args in command array
    declare -a command
    local command=("${@}")

    if [[ "${VERBOSE}" == "y" ]]; then
        conditional_separator_print_before "${method}" "${field}"
        echo "${command[@]}"
        STATUS=("${PIPESTATUS[@]}")

        # Execute given command, unless dry-run mode
        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}"

            # Save PIPESTATUS so we do not destroy it when for instance
            # echo something
            STATUS=("${PIPESTATUS[@]}")
        fi

        if [[ "${STATUS[0]}" -eq 0 ]]; then
            conditional_separator_print_after "${method}" "${field}"
        fi
    else
        if [[ "${DRY_RUN=}" == "y" ]] && [[ "${method}" != "${NONE}" ]]; then
            conditional_separator_print_before "${method}" "${field}"
            echo "${command[*]}"
            STATUS=("${PIPESTATUS[@]}")
        else
            if [[ -n "${field}" ]]; then
                # Need to get a new-line after the prefix
                print_prefix "${field}"
                echo ""
            fi
        fi

        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}" &>/dev/null
            STATUS=("${PIPESTATUS[@]}")
            if [[ "${STATUS[0]}" -ne 0 ]]; then
                print_command_failure_status "${STATUS[0]}" "${command[*]}"
            fi
        fi

        if [[ "${DRY_RUN=}" == "y" ]] && [[ "${method}" != "${NONE}" ]]; then
            conditional_separator_print_after "${method}" "${field}"
        fi
    fi

    return "${STATUS[0]}"
}


function make_destination()
{
    local mg="${1}"
    local name="${2}"
    local version="${3}"
    local result=""

    if [[ -n "${mg}" ]]; then
        if [[ -n "${version}" ]]; then
            result="${mg}/${name}/${version}"
        fi
    elif [[ -n "${version}" ]]; then
        result="${name}/${version}"
    else
        result="${name}"
    fi

    echo "${result}"
}


function make_replication_message()
{
    local prefix="${1}"
    local name="${2}"
    local version="${3}"
    local destination="${4}"

    local result=""

    if [[ "${name}" == "${destination}" ]]; then
        echo "${BOLD}${prefix}${CLEAR} ${name}..."
    else
        echo "${BOLD}${prefix}${CLEAR} ${name} ${version} to ${destination}..."
    fi

    echo "${result}"
}


# Include tag handling functions.
# shellcheck source=./.tag_handling.bash
source "${METADATATOOLS_HOME}/.tag_handling.bash"


# Regex pattern used for capturing name of repo
GIT_BITBUCKET_REPO_PATTERN=".*/([^/]+).git"
GIT_TFS_REPO_PATTERN=".*/_git/([^/]+)"
GIT_REPO_PATTERN="^${GIT_BITBUCKET_REPO_PATTERN}|${GIT_TFS_REPO_PATTERN}$"

# source: Type of service to use when replicating, e.g. git
# uri: From where to obtain the data
# mg: Material Group name, e.g. 97-60 [optional]
# version: Version identifier to use, e.g. "x.y.z" [optional]
#
# NOTE: Name of destination folder is derived from uri, mg, and
# version using the function make_destination().
function replicate_data()
{
    local source="${1}"
    local uri="${2}"
    # Make $3 optional by having default value be an empty string
    local mg="${3:-}"
    # Make $4 optional by having default value be an empty string
    local version="${4:-}"
    # Make $5 optional by having default value be $_FRIJA_JIRA
    local jira="${5:-${_FRIJA_JIRA}}"

    local destination=""
    local message=""
    local name=""

    # Make command to be a local variable and an array
    declare -a command

    case "${source}" in
        git)
            if [[ "$uri" =~ $GIT_REPO_PATTERN ]]; then
                name="${BASH_REMATCH[2]:-${BASH_REMATCH[1]}}"
            else
                print_error "Unsupported ${BOLD}Git repo URI path${CLEAR}: URI is '${uri}' and pattern is '${GIT_REPO_PATTERN}', aborting." 6
            fi

            destination=$(make_destination "${mg}" "${name}" "${version}")
            if [[ ! "${WORDY}" == "n" ]]; then
                message=$(make_replication_message "Cloning" "${name}" \
                                                   "${version}" \
                                                   "${destination}")
            fi
            command=("${FIRST}" "${message}" git clone "$uri" "$destination")

            if [[ "${DEBUG}" == "y" ]]; then
                {
                    echo "*** $LINENO  jira: '${jira}'"
                    echo "*** $LINENO  name: '${name}'"
                    echo "*** $LINENO  destination: '${destination}"''
                    echo "*** $LINENO  command: '${command[*]}'"
                } >&2
            fi

            if [[ ! -d "$destination" ]]; then
                if [[ -z "${message}" ]]; then
                    print_dot
                fi
                run "${command[@]}"
            fi

            # Enter repo
            if [[ "${DRY_RUN}" != "y" ]]; then
                if [[ "${DEBUG}" == "y" ]]; then
                    echo "*** $LINENO  Entering '${destination}'" >&2
                fi
                pushd "${destination}" &> /dev/null
            fi

            if [[ -n "${version}" ]] && \
                   [[ "${version}" != "${NON_VERSION}" ]]; then
                # In this mode a specific commit is implicitly pointed
                # to via a tag with the same name as the version.

                # First validate that tag exists and that it points to
                # the correct commit
                if [[ "${DEBUG}" == "y" ]]; then
                    echo "*** $LINENO  Validating tag '${version}'" >&2
                fi
                validate_tag "${version}"

                # Checkout specific version
                if [[ ! "${WORDY}" == "n" ]]; then
                    message="${name}: Switching repo to version ${CLEAR}${version}"
                else
                    print_dot
                fi
                command=("${MIDDLE}" "${message}" git checkout "${version}")
                run "${command[@]}"

                # Make repo READ ONLY in the sense that it is not possible
                # to push from it
                if [[ ! "${WORDY}" == "n" ]]; then
                    message="  Block pushes from this repo"
                else
                    print_dot
                fi
                command=("${MIDDLE}" "${message}" \
                                     git config \
                                     "remote.origin.pushurl" \
                                     "www.non-existing.com")
                run "${command[@]}"
            elif [[ -n "${jira}" ]]; then
                # No specific version is given, this mean that user
                # should work on a feature branch for the repo
                local featureBranch;
                featureBranch=$(git_find_feature_branch "${destination}" \
                                                        "${jira}")

                # Switch to feature branch
                if [[ ! "${WORDY}" == "n" ]]; then
                    message="${name}: Switching to branch\\n  ${CLEAR}${featureBranch}"
                else
                    print_dot
                fi
                command=("${LAST}" "${message}" \
                                   git checkout "${featureBranch}")
                run "${command[@]}"
            fi

            # Leave repo
            if [[ "${DRY_RUN}" != "y" ]]; then
                if [[ "${DEBUG}" == "y" ]]; then
                    echo "*** $LINENO  Leaving '${destination}'" >&2
                fi
                popd &> /dev/null
            fi
            ;;
        *)
            print_error "Unsupported SOURCE: '${source}' for '${uri}', aborting." 6
            ;;
    esac
}


function git_find_feature_branch()
{
    local result=""
    local repoLocation="${1}"
    local jira="${2:-${_FRIJA_JIRA}}"
    local branches=""

    # Enter repo
    if [[ "${DRY_RUN}" != "y" ]]; then
        pushd "${repoLocation}" &> /dev/null
    fi

    ## Get all remote branches
    if [[ "${DRY_RUN}" == "y" ]]; then
        print_message "git branch --remotes | grep -v HEAD"
    else
        branches=$(git branch --remotes | grep -v HEAD)
    fi

    # Leave repo
    if [[ "${DRY_RUN}" != "y" ]]; then
        popd &> /dev/null
    fi

    # Find feature branch matching current Jira issue (signified by
    # folder name containing .frija folder). If no such feature branch
    # exist select develop, and if no such branch exist fall back to
    # develop.
    while read -r remoteBranch; do
        # Strip "origin/" prefix from each remote branch
        remoteBranch="${remoteBranch#*/}"

        # Order is not important here. What is important to note here
        # is that if we find a feature branch that starts with
        # $_FRIJA_JIRA then we break out from the while loop after
        # saving the branch name in $result.
        #
        # If we find develop branch while searching, then set $result
        # to it. Just in case we don't find any feature branch. And
        # continue searching. We overwrite $result regardless of what
        # it contain (remember: if we had found a feature branch
        # before we reach this point we would have already broken out
        # from the while). And if it contained "master" then it does
        # not matter since "develop" trumps "master" in this case.
        #
        # And finally, only overwrite $result with "master" when it is
        # an empty string; that is if we have found develop before
        # master then $result will not be left as it is.
        if [[ "${remoteBranch}" == "feature/${jira}"* ]]; then
            result="${remoteBranch}"
            break
        elif [[ "${remoteBranch}" == "develop" ]]; then
            result="${remoteBranch}"
        elif [[ "${remoteBranch}" == "master" ]] && [[ -z "${result}" ]]; then
            result="${remoteBranch}"
        fi
    done <<< "${branches}"

    if [[ -z "${result}" ]]; then
        # Sanity check failure! We could not find any feature branch,
        # nor develop nor master branch. This is a very strange repo
        # and we can not do anything meaningful appart from bailing
        # out.
        local repoName
        repoName=$(pwd)

        # Remove everything up to and including last '/' in current
        # path (pwd)
        repoName=${repoName##*/}

        print_error "Could find neither a feature branch for Jira ${_FRIJA_JIRA} nor develop branch or master branch for repo ${repoName}." 7
    fi

    echo "${result}"
}


function update_git_repo()
{
    local repoFolder="${1}"
    local mode="${2}"
    local force="${3:-}"

    # In case $mode is $NONE then both $firstMode and $lastMode should
    # booth be none
    local firstMode="${mode}"
    local lastMode="${mode}"

    case "${mode}" in
        "${SINGLE}")
            firstMode="${FIRST}"
            lastMode="${LAST}"
            ;;
        "${FIRST}")
            firstMode="${FIRST}"
            lastMode="${MIDDLE}"
            ;;
        "${MIDDLE}")
            firstMode="${MIDDLE}"
            lastMode="${MIDDLE}"
            ;;
        "${LAST}")
            firstMode="${MIDDLE}"
            lastMode="${LAST}"
        ;;
    esac

    local -a command=()
    local message=""

    if [[ "${VERBOSE}" == "y" ]]; then
        message="${1}"
    fi

    command=("${firstMode}" "${message}" git fetch)
    run "${command[@]}"

    local currentBranch
    currentBranch=$(git rev-parse --abbrev-ref HEAD);

    # Get all local branches that tracks remote branches
    local branches
    branches=$(git remote show origin -n | \
                   awk '/merges with remote/{print $5" "$1}')

    # Above variable $branches contains a newline for each branch and
    # we want to know the number of branches. We do this by converting
    # the variable to an array called $branchList and then count the
    # items in the array.
    local -a branchList=()

    # We are going to modify $IFS so we have to save it first as the
    # while loop below depend on the default value.
    local savedIFS="${IFS}"
    # Set $IFS to newline so we split on newlines. No need to worry
    # about globbing as branch names may not contain such characters.
    IFS=$'\n'
    # We WANT to split on newlines, hence no quoting
    # shellcheck disable=SC2206
    branchList=(${branches})
    # Finally count number of branches!
    local -i branchCount=${#branchList[@]}
    # Restore $IFS to its old value
    IFS="${savedIFS}"

    # We need to keep track of if there were any changes to any of the
    # found branches or not. First assume there are no changes, i.e.
    # no commands run within the while loop. If this situation holds
    # after the while-loop then we should print our own separator,
    # otherwise not.
    local noChanges="y"

    # Use a counter to keep track on which iteration we are on; this
    # enables us to detect the last iteration so we can format output
    # accordingly
    declare -i index=0
    while read -r remoteBranch localBranch; do
        local aRemoteBranch=""
        local aLocalBranch=""
        local behindCount=""
        local aheadCount=""

        message=""

        if [[ "${DEBUG}" == "y" ]]; then
            echo "*** ${LINENO}  verbose='${VERBOSE}', debug='${DEBUG}', MG='${MG}', remoteBranch='${remoteBranch}', localBranch='${localBranch}'" >&2
        fi

        # Increment counter at start of each iteration as this makes
        # it possible to directly compare against the array length
        index=$(( index +1 ))

        # Use explicit names for remote and local branches
        aRemoteBranch="refs/remotes/origin/${remoteBranch}";
        aLocalBranch="refs/heads/${localBranch}";

        # Get number of commits branch is behind
        behindCount=$(git rev-list --count "${aLocalBranch}..${aRemoteBranch}" \
                          2>/dev/null)
        behindCount=$(( behindCount + 0 ));

        # Get number of commits branch is ahead
        aheadCount=$(git rev-list --count "${aRemoteBranch}..${aLocalBranch}" \
                         2>/dev/null)
        aheadCount=$(( aheadCount + 0 ));

        if [[ "${DEBUG}" == "y" ]]; then
            echo "*** ${LINENO}  aheadCount='${aheadCount}', behindCount='${behindCount}'" >&2
        fi

        # Default mode to use is $MIDDLE, but when we are on the last
        # iteration it should be $lastMode
        local separatorMode="${MIDDLE}"
        if (( index == branchCount )); then
            separatorMode="${lastMode}"
        fi

        if [[ "${behindCount}" -gt 0 ]]; then
            # Indicate that a separator has been written to the terminal
            noChanges="n"

            print_newline_after_dot
            if [[ "${VERBOSE}" == "y" ]]; then
                # In this branch there is no command executed so we
                # have to finnish off with our very oven separator
                conditional_separator_print_before "${separatorMode}" \
                                                   "${repoFolder}"
            fi

            if [[ "${aheadCount}" -gt 0 ]]; then
                print_message " Branch ${localBranch} is ${behindCount} commit(s) behind and ${aheadCount} commit(s) ahead of origin/${remoteBranch}."
                print_message "   ${BOLD}Could not be fast-forwarded!${CLEAR}"

                if [[ -n "${force}" ]]; then
                    print_message "Forcing local branch to point to remote branch..."
                    # Set a save-point in case something went wrong
                    message="Current commit saved as tag ${BOLD}frija${CLEAR}"
                    command=("${SINGLE}" "${message}" git tag --force frija)
                    run "${command[@]}"

                    message="Switching temporarily to master branch"
                    command=("${SINGLE}" "${message}" git checkout master)
                    run "${command[@]}"

                    message="Forcing local branch\\n ${localBranch}\\nto point to\\n origin/${remoteBranch}\\n(same commit as remote branch)"
                    command=("${SINGLE}" "${message}" \
                                         git branch -f \
                                         "${localBranch}" \
                                         "origin/${remoteBranch}")
                    run "${command[@]}"

                    message="Switching back to local branch"
                    command=("${SINGLE}" "${message}" \
                                         git checkout \
                                         "${localBranch}")
                    run "${command[@]}"

                    print_separator
                    print_message "${BOLD}Note:${CLEAR} You can always get back to old branch HEAD via tag ${BOLD}frija${CLEAR}."
                    print_separator
                elif [[ "${VERBOSE}" == "y" ]]; then
                    # In this branch there is no command executed so we
                    # have to finnish off with our very oven separator
                    conditional_separator_print_after "${separatorMode}" \
                                                      "${repoFolder}"
                fi
            elif [[ "${localBranch}" == "${currentBranch}" ]]; then
                print_message " Branch ${localBranch} was ${behindCount} commit(s) behind of origin/${remoteBranch}."
                print_message "   Fast-forward merge"

                command=("${separatorMode}" "${repoFolder}" \
                                            git merge --ff-only \
                                            --quiet \
                                            "${aRemoteBranch}")
                run "${command[@]}"
            else
                print_message " Branch ${localBranch} was ${behindCount} commit(s) behind of origin/${remoteBranch}."
                print_message "   Resetting local branch to remote"
                command=("${separatorMode}" "${repoFolder}" \
                                            git branch --force \
                                            "${localBranch}" \
                                            --track \
                                            "${aRemoteBranch}")
                run "${command[@]}"
            fi
        fi
    done <<< "${branches}"

    if [[ "${noChanges}" == "y" && "${VERBOSE}" == "y" ]] && \
           [[ ${mode} == "${LAST}" || ${mode} == "${SINGLE}" ]]; then
        conditional_separator_print_after "${mode}" "${repoFolder}"
    fi
}


# Test if _BOOTSTRAP_PATH is set to any value
if [[ -v _BOOTSTRAP_PATH ]]; then
    # When we are sourced from the bootstrap script, it is here we
    # should return back to it.
    return
fi


# Dummy implementation of a cleanup function called from the main
# cleanup function. A command may override this implementation to get
# some extra cleanup done at exit.
function _frija_cleanup_function()
{
    echo "" > /dev/null
}


function cleanup()
{
    if [[ -n "${_FRIJA_HOME}" ]]; then
        if [[ -d "${_FRIJA_FOLDER_PATH}" ]]; then
            # shellcheck disable=SC2164
            cd "${_FRIJA_FOLDER_PATH}"

            # Remove all files stored here
            rm -fr ./*
        fi
    fi

    _frija_cleanup_function
}

# Install exit trap function that will be called when script exits
trap cleanup EXIT
