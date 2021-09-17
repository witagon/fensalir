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
    local target_mode="${1}"
    local current_mode_name="${2}"
    local current_mode="${!2}"  # Indirect parameter expansion
    local option="${3}"

    if [[ -z "${current_mode}" ]]; then
        # Current mode unset; set it indirectly using declare
        declare -g "${current_mode_name}"="${target_mode}"
    elif [[ "${current_mode}" != "${target_mode}" ]]; then
        print_error "${BOLD}'${option}'${CLEAR} option may only be used in ${BOLD}${target_mode}${CLEAR} mode."
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


function print_separator()
{
    if [[ -z "${1:-}" ]];
    then
        echo "--------------------"
    else
        echo "----- $1 -----"
    fi
}


function conditional_separator_print_before()
{
    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    if [[ ("${method}" == "${SINGLE}") || ("${method}" == "${FIRST}") ]]; then
        print_separator "${field}"
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
        echo
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

    local destination=""
    local message=""
    local name=""
    local replication_type=""

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
            message=$(make_replication_message "Cloning" "${name}" "${version}" "${destination}")
            command=(git clone "$uri" "$destination")
            replication_type="cloned"
            ;;
        *)
            print_error "Unsupported SOURCE: '${source}' for '${uri}', aborting." 6
            ;;
    esac


    if [[ "${DEBUG}" == "y" ]]; then
        echo "*** $LINENO  name: $name"
        echo "*** $LINENO  destination: $destination"
        echo "*** $LINENO  command: ${command[*]}"
    fi

    print_message "$message"
    if [[ ! -d "$destination" ]]; then
        if [[ "${VERBOSE}" == "y" ]]; then
            # Send any stderr output from command to terminal
            print_separator "${name}"
            if [[ "${DRY_RUN}" == "y" ]]; then
                echo "${command[@]}"
            else
                "${command[@]}"
            fi
            print_separator "${name}"
            echo ""
        else
            if [[ "${DRY_RUN}" == "y" ]]; then
                echo "${command[@]}"
            else
                # Ignore anything sent to stdout and stderr
                ! "${command[@]}" &>/dev/null
                STATUS=("${PIPESTATUS[@]}")
                if [[ "${STATUS[0]}" -ne 0 ]]; then
                    print_command_failure_status "${STATUS[0]}" "${command[*]}"
                fi
            fi
        fi
    else
        print_message "   ${destination} already ${replication_type}, skipping."
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
