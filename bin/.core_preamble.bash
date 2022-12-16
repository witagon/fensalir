# This file is sourced by .preamble.bash.

# Remove longest matching prefix matching "*/", i.e. all paths up to
# but not including the program name
_FRIJA_PROGRAM_NAME="${_FRIJA_PROGRAM_PATH##*/}"

# If command is "frija-build" then _FRIJA_NAME will be "build"
_FRIJA_USAGE_NAME=${_FRIJA_PROGRAM_NAME//-/ }

# This global variable is dynamically set depending on Feature ID,
# that is it is the path to a folder that contain
# _FRIJA_CONFIG_FOLDER_NAME which in turn depend on Feature ID.
# _FRIJA_CONFIG_FOLDER_PATH is in turn a convenience variable that
# contain the path to the config folder in _FRIJA_CONFIG_FOLDER_NAME.
_FRIJA_HOME=""

# This global variable hold the current working directory. What
# differs compared to PWD is that it is set once during the script
# execution and that it is corrected if PWD points to within a PWA
# folder but contain the actual path and not the symlinked "/p/pwa/"
# path.
_FRIJA_PWD=""

# TODO: Is this good or bad?
#
# Guard against this script being sourced multiple times.
#
# Note: -v tests if variable name is set or not.
if [[ -v _CORE_PREAMBLE_IS_SOURCED ]]; then
    return
fi
_CORE_PREAMBLE_IS_SOURCED="y"

# Include common configuration (global variables)
# shellcheck source=./.core_config.bash
source "${REPO_TOOLS_HOME}/.core_config.bash"

# TODO: Add _FRIJA_ prefix
#
# Regex pattern used for capturing name of repo
#
# TODO: Better to use stricter regexp such as below?
# ^[a-zA-Z]+://.*/([^/]+)[._]([a-zA-Z]+)$
GIT_BITBUCKET_REPO_PATTERN=".*/([^/]+).git"
GIT_TFS_REPO_PATTERN=".*/_git/([^/]+)"
GIT_REPO_PATTERN="^${GIT_BITBUCKET_REPO_PATTERN}|${GIT_TFS_REPO_PATTERN}$"

GIT_REPO="git"


# Destructively filter out empty elements from the indirectly
# referenced array. Note that the array indexes are unmodified.
#
# First parameter; Name of array to trim
function _frija_trim_array()
{
    local arrayname="${1}"

    # Expand the array reference to the number of elements in the
    # array. If Bash 4.3 or newer can be used then replace with named
    # references instead to get simpler code.
    local arrayRef="${arrayname}[@]"
    declare -i index=0
    local element=""
    for element in "${!arrayRef}"; do
        if [[ -z "${element}" ]]; then
            unset "${arrayname}[${index}]"
        fi
        (( index++ ))
    done
}


# Destructively filter out elements equal to the given value from the
# indirectly referenced array. Note that the array indexes are
# unmodified.
#
# First parameter; Name of array to filter
#
# Second parameter; Element value to remove from array
#
# Third parameter; If non-empty, trim any empty elements from the array as well
function _frija_filter_array()
{
    local arrayname="${1}"
    local value="${2}"
    local trim="${3}"

    # Expand the array reference to the number of elements in the
    # array. If Bash 4.3 or newer can be used then replace with named
    # references instead to get simpler code.
    local arrayRef="${arrayname}[@]"
    declare -i index=0
    local element=""
    for element in "${!arrayRef}"; do
        # Update the indirect reference to point to specific element
        # in array. Named references would simplify this as well.
        if [[ -n "${trim}" && -z "${element}" ]] \
               || [[ "${element}" == "${value}" ]]
        then
            unset "${arrayname}[${index}]"
        fi
        (( index++ ))
    done

    print_debug_array "${arrayname}"
}


# Create a natural language sequence from a entries in an array. That
# is, if the array is (a b c) then the output from this function could
# the string "a, b, and c". On the other hand, if the array is (a b)
# then the output could be "a and b".
#
# First parameter is the conjunction to use, that is "and" or "or"
#
# Second parameter is the name of the array to create the sequence for.
#
# Third parameter If provided and set to $BOLD, then each item in the
#                 list is bolded. (Optional)
function _frija_create_sentence_sequence()
{
    local conjunction="${1}"
    local arrayname="${2}"
    local bold="${3:-}"

    local prefix=""
    local suffix=""
    if [[ "${bold}" == "${BOLD}" ]]; then
        print_debug "Using BOLD"
        prefix="${BOLD}"
        suffix="${CLEAR}"
    fi

    # Create an array reference
    local arrayRef="${arrayname}[@]"
    # Expand the array reference to the content of the array and
    # assign it to a new array. If Bash 4.3 or newer can be used then
    # replace with named references instead to get simpler code.
    declare -a tempItems=("${!arrayRef}")
    declare -a items=()

    # Filter out any empty elements from the array by copying
    # non-empty elements to the new array. This is due to that if
    # unset had been used to remove elements from the array then holes
    # in the array would have been created. By copying the array this
    # is avoided since the indices in the new array are consecutive.
    declare -i index=0
    local element=""
    for index in "${!tempItems[@]}"; do
        element="${tempItems[index]}"
        if [[ -n "${element}" ]]; then
            items+=("${element}")
        fi
    done

    local itemSequence=""
    declare -i length=${#items[@]}
    if (( length > 2 )); then
        for entry in "${items[@]::length-1}"; do
            itemSequence+="${prefix}${entry}${suffix}, "
        done
        itemSequence+="and ${prefix}${items[length-1]}${suffix}"
    elif (( length > 1 )); then
        itemSequence="${prefix}${items[0]}${suffix} ${conjunction} "
        itemSequence+="${prefix}${items[1]}${suffix}"
    elif (( length > 0 )); then
        itemSequence="${prefix}${items[0]}${suffix}"
    fi

    echo "${itemSequence}"
}


if [[ "${0}" == "bash" ]]; then
    # Sourced from outside of a frija-command
    return
fi


# Test if _FRIJA_IS_SOURCED is *not* an empty string
# and
# if _BOOTSTRAP_PATH is unset.
#
# -v tests if variable name is set, and negating test gives instead a
# test whether variable is unset or not.
if [[ ! -v _BOOTSTRAP_PATH ]] && [[ -n "${_FRIJA_IS_SOURCED}" ]]; then
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
        local message="Multiple ${BOLD}'${1}'${CLEAR} options not allowed!"
        print_error "${message}" $_FRIJA_EXIT_CMD_LINE_PROBLEMS
    fi
}


function ensure_option_argument_set()
{
    if [[ -z "${2}" ]]; then
        local message="${BOLD}'${1}'${CLEAR} option argument must not be an "
        message+="empty string."
        print_error "${message}" $_FRIJA_EXIT_CMD_LINE_PROBLEMS
    fi
}


# Check if given value is a member of given enum list.
#
# First parameter is value to check
#
# Second parameter is exit code to use if check fails
#
# Rest is list of enum values to check against.
#
# If check fails function abort with an error message.
function ensure_value_in_enum()
{
    # Save value we want to check if it is a member of the given enum
    local value="${1}"

    declare -i exitCode="${2}"

    # Shift argument list so it only contain enum entries
    shift 2

    # Iterate over given enum and see if can find a match with $value
    for item in "$@"; do
        if [[ "${item}" == "${value}" ]]; then
            # Found a match
            return
        fi
    done

    # No match found if we reach this point
    local enum="${*}"
    message="'${value}' does not match any of {${enum// /, }}, aborting."
    # shellcheck disable=SC2086
    print_error "${message}" $exitCode
}


function ensure_mode_set()
{
    declare -a target_mode_list=()
    declare -a option_list=()

    local current_mode_name="${1}"
    local current_mode="${!1}"  # Indirect parameter expansion

    # Move to next option
    shift

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
        local message="${BOLD}Internal error!${CLEAR} No target mode defined."
        print_error "${message}" $_FRIJA_EXIT_INTERNAL_ERROR
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
        local message="${BOLD}'${option}'${CLEAR} option may only be used in "
        message+="${BOLD}${target_mode_list[0]}${CLEAR} mode."
        print_error "${message}" $_FRIJA_EXIT_CMD_LINE_PROBLEMS
    else
        local message="${BOLD}'${option}'${CLEAR} option may only be used in "
        message+="one of ${BOLD}"

        declare -i last_index=$(( list_length - 1 ))
        for key in "${!target_mode_list[@]}"; do
            message+="${target_mode_list[key]}"
            if (( key < last_index )); then
                message+=", "
            fi
        done


        print_error "${message}${CLEAR} modes." $_FRIJA_EXIT_CMD_LINE_PROBLEMS
    fi
}


function ensure_boolean_option_not_set()
{
    if [[ -n "${2}" ]]; then
        if [[ "${2}" != "n" ]]; then
            local message="Multiple ${BOLD}'${1}'${CLEAR} options not allowed!"
            print_error "${message}" $_FRIJA_EXIT_CMD_LINE_PROBLEMS
        fi
    fi
}


function current_date_and_time()
{
    print_debug_enter

    # Separator between date and time of day; default is to use '_'
    # (underscore) as the separator
    local separator="${1:-_}"

    # This is the "now" used for the time and date calculations
    local secondsSinceEpoch=""
    secondsSinceEpoch=$(date "+%s")

    # Finally create a timestamp
    # --utc  : Use UTC
    # --date : Use given value for calculations
    #     %g : 4-digit year
    #     %m : Month of year (01..12)
    #     %d : Day of month (01..28/30/31)
    #     %H : Hour (00..24)
    #     %M : Minute (00..59)
    #     %S : Second (00..59)
    #
    # The format used for the time-of-day follows "military time" as
    # used for instance within US and allied English-speaking military
    # forces
    #
    # - No separator between hours and minutes and 24-hour clock with
    #   leading zero
    #
    # - NATO phonetic alphabet is used for time zone indication; UTC
    #   is 'Zulu' or just 'Z'
    timestamp=""
    timestamp=$(date "--utc" \
                     "--date=@${secondsSinceEpoch}" \
                     "+%G-%m-%d${separator}%H%M.%SZ")

    # Delta between UTC and local time zone with sign, for instance
    # CET is +0100 and CEST is +0200
    local tzDelta=""
    tzDelta=$(date "--date=@${secondsSinceEpoch}" "+%z")

    # Create final timestamp
    timestamp="${timestamp}${tzDelta}"

    print_debug_exit "${timestamp}"
    echo "${timestamp}"
}


function get_branch_name()
{
    print_debug_enter "${@}"

    local repopath="${1}"
    local currentBranch=""

    # -C : Switch to $repopath before 'git rev-parse' is executed
    currentBranch=$(git -C "${repopath}" rev-parse --abbrev-ref HEAD)

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

    print_debug_exit "${currentBranch}"
    echo "${currentBranch}"
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
    message="Aborting, GNU getopt not in search path."
    print_error "${message}" $_FRIJA_EXIT_GETOPT_NOT_FOUND
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
    exit $_FRIJA_EXIT_GETOPT_NOT_FOUND
fi

# To handle quoting correctly in output from getopt we have to do this
eval set -- "${_FRIJA_PARSED}"


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

    print_newline_only_after_dot

    print_separator
    local message="${command}\\n"
    message+="failed with exit code ${status}, "
    message+="please rerun with --verbose or -v to get more information."

    _frija_fold "${message}" "0" "" "Command error:"
}


function conditional_separator_print_before()
{
    print_debug_enter "${@}"

    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    # Whether entire message should be bolded or not; DEFAULT bolded
    local isBold="${2:-${BOLD}}"

    if [[ "${method}" == "${SINGLE}" ]] || [[ "${method}" == "${FIRST}" ]]; then
        if [[ -n "${field}" ]]; then
            if [[ "${isBold}" == "${BOLD}" ]]; then
                print_separator "${BOLD}${field}${CLEAR}"
            else
                print_separator "${field}"
            fi
        fi
    fi

    print_debug_exit
}


function conditional_separator_print_after()
{
    print_debug_enter "${@}"

    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    if [[ "${method}" == "${SINGLE}" ]] || [[ "${method}" == "${LAST}" ]]; then
        if [[ -n "${field}" ]]; then
            print_separator "${BOLD}Done${CLEAR} ${field}"
            print_message
        fi
    fi

    print_debug_exit
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
        if [[ "${DRY_RUN=}" == "y" ]] && [[ "${method}" != "${NONE}" ]]; then
            conditional_separator_print_before "${method}" "${field}"
            echo "${command[*]}  >> ${destination}"
            STATUS=("${PIPESTATUS[@]}")
        else
            if [[ -n "${field}" ]]; then
                # Need to get a new-line after the prefix
                print_prefix "${field}"
                echo ""
            fi
        fi

        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}" >> "${destination}" 2> /dev/null
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
        if [[ "${DRY_RUN=}" == "y" ]] && [[ "${method}" != "${NONE}" ]]; then
            print_message "2.1"
            conditional_separator_print_before "${method}" "${field}"
            echo "${command[*]}  >| ${destination}"
            STATUS=("${PIPESTATUS[@]}")
        else
            if [[ -n "${field}" ]]; then
                # Need to get a new-line after the prefix
                print_prefix "${field}"
                echo ""
            fi
        fi

        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}" >| "${destination}" 2> /dev/null
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

    print_debug "Command: ${*}"
    print_debug "VERBOSE='${VERBOSE}'"
    if [[ "${VERBOSE}" == "y" ]]; then
        print_debug "field='${field}'"
        conditional_separator_print_before "${method}" "${field}"
        print_debug "${command[@]}"
        STATUS=("${PIPESTATUS[@]}")

        # Execute given command, unless dry-run mode
        if [[ "${DRY_RUN=}" != "y" ]]; then
            # Redirect ALL command output to stderr
            ! "${command[@]}" 1>&2

            # Save PIPESTATUS so we do not destroy it when for instance
            # echo something
            STATUS=("${PIPESTATUS[@]}")
        fi

        if [[ "${STATUS[0]}" -eq 0 ]]; then
            conditional_separator_print_after "${method}" "${field}"
        fi
    else
        if [[ "${DRY_RUN=}" == "y" ]] && [[ "${method}" != "${NONE}" ]]; then
            print_debug "field='${field}'"
            conditional_separator_print_before "${method}" "${field}"
            print_debug "${command[*]}"
            STATUS=("${PIPESTATUS[@]}")
        else
            if [[ -n "${field}" ]]; then
                print_debug "field='${field}'"
                print_message "${field}"
            fi
            print_message "${command[*]}"
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


# Run a process in an isolated environment. That is remove all
# environment variables (including PATH) before the script
# frija_isolate.bash is executed in a separate process. This script
# then rebuild the target environment based on the content in the
# referenced .seci files.
#
# First parameter: Method is one of SINGLE, FIRST, LAST, or NONE
#
# Second parameter: Value to use within separator
#
# Third parameter: Path to locale repo to read .seci-files from
#
# Fourth parameter: Version tag to select within repo or "floating"
#                   for whatever is visible in the file system
#
# Fifth parameter: List of .seci-files to add to isolated environment
function run_isolated()
{
    local method="${1}"
    local field="${2}"
    local localePath="${3}"
    local version="${4}"
    local seciList="${5}"

    # Skip first five arguments up to but not including the command to
    # run
    shift 5

    # Any environment variables to explicitly set in the cleared
    # environment are listed in this variable, for instance DEBUG for
    # debug printouts and USERNAME in Windows.
    local extraVariables=""
    if [[ "${DEBUG}" == "y" ]]; then
        # Force debug printouts in frija_isolate.bash script
        extraVariables+="DEBUG=t "
    fi
    print_debug "DEBUG='${DEBUG}'"

    if [[ "${OPERATING_SYSTEM}" == "${WINDOWS_OS}" ]]; then
        extraVariables+="USERNAME=${USERNAME} "
        print_debug "USERNAME='${USERNAME}'"
    fi

    print_debug "extraVariables='${extraVariables}'"

    # Use env command to create a clean environment (absolute bare
    # minimum set of environment variables), that is not even $PATH is
    # inherited. In this minimalistic environment the
    # frija_isolate.bash script is executed which in turn sets up a
    # new environment based on what is provied in the $seciList
    # variable. Once that is done the actual command is executed in
    # this prestine environment; this latter part (which command and
    # with which options) is hidden in the $@ expansion.
    #
    # Note: $BASH is set by Bash itself and "Expands to the full file
    # name used to invoke this instance of bash" according to the
    # manual page for Bash.
    #
    # shellcheck disable=SC2086
    ! run "${method}" "${field}" \
        "env" "--ignore-environment" \
        ${extraVariables} \
        "${BASH}" "--norc" "--noprofile" \
        "${REPO_TOOLS_HOME}/frija_isolate.bash" \
        "${localePath}" "${version}" "${seciList}" \
        "${@}"
    STATUS=("${PIPESTATUS[@]}")
    print_message "Executed command was: ${*}"

    return "${STATUS[0]}"
}


# Run a process in a non-isolated environment. That is the current
# environment variables (including PATH) are inherited before the
# script frija_isolate.bash is executed in a separate process. This
# script then adds to the target environment based on the content in
# the referenced .seci files.
#
# First parameter: Method is one of SINGLE, FIRST, LAST, or NONE
#
# Second parameter: Value to use within separator
#
# Third parameter: Path to locale repo to read .seci-files from
#
# Fourth parameter: Version tag to select within repo or "floating"
#                   for whatever is visible in the file system
#
# Fifth parameter: List of .seci-files to add to isolated environment
function run_nonisolated()
{
    local method="${1}"
    local field="${2}"
    local localePath="${3}"
    local version="${4}"
    local seciList="${5}"

    # Skip first five arguments up to but not including the command to
    # run
    shift 5

    local debugExpression=""
    if [[ "${DEBUG}" == "y" ]]; then
        # Force debug printouts in frija_isolate.bash script
        debugExpression="DEBUG=t"
    fi

    print_debug "DEBUG='${DEBUG}'"
    print_debug "debugExpression='${debugExpression}'"

    # Use env command to create a clean environment (absolute bare
    # minimum set of environment variables), that is not even $PATH is
    # inherited. In this minimalistic environment the
    # frija_isolate.bash script is executed which in turn sets up a
    # new environment based on what is provied in the $seciList
    # variable. Once that is done the actual command is executed in
    # this prestine environment; this latter part (which command and
    # with which options) is hidden in the $@ expansion.
    #
    # Note: $BASH is set by Bash itself and "Expands to the full file
    # name used to invoke this instance of bash" according to the
    # manual page for Bash.
    ! run "${method}" "${field}" \
        "${BASH}" "--norc" "--noprofile" \
        "${REPO_TOOLS_HOME}/frija_isolate.bash" \
        "${localePath}" "${version}" "${seciList}" \
        "${@}"
    STATUS=("${PIPESTATUS[@]}")

    return "${STATUS[0]}"
}


REPO_SEPARATOR="__"

# Creates a path from given composite-name, repo-name and optional version.
# The separator used between repo-name and optional version is defined
# by $REPO_SEPARATOR.
#
# NOTE: Name is assumed to be a non-empty string. However composite is
# allowed to be an empty string even though it is a mandatory
# parameter.
function make_destination()
{
    print_debug_enter "${@}"

    local composite="${1}"
    local name="${2}"
    local version="${3:-}"
    local result=""

    if [[ "${version}" == "${NON_VERSION}" ]]; then
        version=""
    fi

    if [[ -n "${composite}" ]]; then
        if [[ -n "${version}" ]]; then
            result="${composite}/${name}${REPO_SEPARATOR}${version}"
        else
            result="${composite}/${name}"
        fi
    elif [[ -n "${version}" ]]; then
        result="${name}${REPO_SEPARATOR}${version}"
    else
        result="${name}"
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


# Remove variation point ID from given string. It is assumed that the
# variation point ID is the last part of the name and that it is
# preceded by a _' and does not in itself contain any '_' characters.
# It is assumed that the resulting string is still a unique value
# within a system/sub-system.
#
# For instance if given value is "FOO-BAR_GAZONK_42" then this
# function will return "FOO-BAR_GAZONK".
#
# It is an error to try to transform a string that does not end with
# a variation point ID.
#
# First parameter is the string value to transform.
#
# Return value is transformed string.
function transformVariationPoint()
{
    print_debug_enter "${@}"

    local name="${1}"

    local result=""

    # Create regex that catches the part of the name that precedes the
    # last '_' in the name. What follows the last '_' is the variation
    # point ID and should be removed for all variation points. It is
    # also assumed that the name without this ID is still unique
    # within a system/sub-system.
    local regex="^(.+)_([^_]+)$"
    if [[ "${name}" =~ ${regex} ]]; then
        print_debug "Field #1='${BASH_REMATCH[1]}'"
        print_debug "Field #2='${BASH_REMATCH[2]}'"

        result="${BASH_REMATCH[1]}"
    else
        local message="Not possible to remove variation point ID from "
        message+="'${name}'. A variation point ID is the last part of a repo "
        message+="name that starts with '_' and is not followed any more '_' "
        message+="characters. For instance 'FOO-BAR_GAZONK_42' has variation "
        message+="point ID '_42'. Aborting due to this."
        print_error "${message}" _FRIJA_EXIT_OTHER_PROBLEM
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


function make_replication_message()
{
    print_debug_enter "${@}"

    local prefix="${1}"
    local name="${2}"
    local version="${3}"
    local destination="${4}"
    local preposition="${5:-to}"

    local result="${BOLD}${prefix}${CLEAR} ${name}"

    if [[ "${name}" != "${destination}" ]]; then
        if [[ -n "${version}" ]]; then
            result+=" ${version} ${preposition} ${BOLD}${destination}${CLEAR}"
        else
            result+=" ${preposition} ${BOLD}${destination}${CLEAR}"
        fi
    fi
    result+="..."

    print_debug_exit "${result}"
    echo "${result}"
}


# Include tag handling functions.
# shellcheck source=./.tag_handling.bash
source "${REPO_TOOLS_HOME}/.tag_handling.bash"


# Return VCS kind based on given path or URI. That is, if given
# parameter starts with '/' then it is assumed that it is a file
# system path pointing to a repo and different VCS systems are queried
# based on this path if they recognize the repo. The first VCS that
# claims it recognizes the repo is assumed to define the kund of repo.
#
# Otherwise, the given parameter is expected to be a URI and VCS kind
# is deduced from inspecting this URI.
#
# NOTE: Currently only Git is supported for path based VCS
# identification. For URI based identification only URIs starting with
# 'ssh:' and ends with '.git', i.e. standard Git URIs.
#
# First parameter is either a path or a URI to a repo.
#
# TODO: Duplicate of function in .vcs_functions.bash ?
function frija_deduce_vcs_type()
{
    print_debug_enter "${@}"

    local uri="${1}"
    local result=""

    print_debug "uri='${uri}'"

    if [[ "${uri}" == "/"* ]]; then
        # Do not abort script if non-zero exit code is returned
        # - Allow command to fail with !'s side effect on errexit
        # - Use return value from ${PIPESTATUS[0]}, because ! hosed $?
        print_debug "git -C '${uri}' rev-parse &>/dev/null"
        ! git -C "${uri}" rev-parse &>/dev/null
        declare -i exitCode=${PIPESTATUS[0]}
        if (( exitCode == 0 )); then
            result="${GIT_REPO}"
        else
            local message="Unknown VCS type for repo '${uri}' "
            message+="(exit code ${exitCode})"
            print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
        fi
    else
        # Check if we have been given a URI
        local result=""

        if [[ "${uri}" =~ ^[a-zA-Z]+://.*/[^/]+[._]([a-zA-Z]+)$ ]]; then
            # Ensure result is always in lowercase due to ',,'
            # parameter expansion
            local result="${BASH_REMATCH[1],,}"
        fi

        if [[ -z "${result}" ]]; then
            local message="Unknown repo URI format: '${uri}'"
            print_error "${message}" $_FRIJA_EXIT_CMD_LINE_PROBLEMS
        fi

        case "${result}" in
            git)
                result="${GIT_REPO}"
                ;;
            *)
                local message="Can't deduce VCS type from given URI: '${uri}'"
                print_error "${message}" $_FRIJA_EXIT_CMD_LINE_PROBLEMS
                ;;
        esac
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


# Either checks out a specific tag (and enter headless state) or
# feature-branch (based on Feature ID) or develop or master. That is,
# if Feature ID can't be found then fallback is develop or master in
# that priority order.
#
# First parameter is the "base" that is a relative path from
# $_FRIJA_HOME to the repo
#
# Second parameter is a version number that can be validated, or
# $NON_VERSION, or an empty string.
#
# Third parameter is only used when second parameter (version) is an
# empty string. When that is the case it is used to construct feature
# branch name to checkout.
function checkout_branch()
{
    print_debug_enter "${@}"
    print_debug "PWD='${PWD}'"

    local base="${1}"
    local version="${2}"
    local featureID="${3:-${_FRIJA_FEATURE_ID}}"

    local result=""

    print_debug "base: '${base}'"
    print_debug "version: '${version}'"
    print_debug "featureID: '${featureID}'"

    local message=""

    if [[ -n "${version}" ]] && \
           [[ "${version}" != "${NON_VERSION}" ]]; then
        # In this mode a specific commit is implicitly pointed
        # to via a tag with the same name as the version.

        # First validate that tag exists and that it points to
        # the correct commit
        print_debug "Validating tag '${version}'"
        validate_tag "${version}"

        # Checkout specific version
        if [[ "${WORDY}" == "y" ]]; then
            message="${BOLD}Switching${CLEAR} repo ${base} to version "
            message+="${BOLD}${version}${CLEAR}"
        else
            print_dot
        fi

        command=("${SINGLE}" "${message}" \
                             git -C "${_FRIJA_HOME}/${base}" \
                             checkout "${version}")
        run "${command[@]}"

        print_debug "Setting result='${version}'"
        result="${version}"
    elif [[ -n "${featureID}" ]]; then
        # No specific version is given, this mean that user should
        # work on a feature branch for the repo (or develop or master
        # branches should be used, but they are lumped together with
        # feature-branches here)
        local featureBranch;
        featureBranch=$(git_find_feature_branch "${base}" "${featureID}")

        # Switch to feature branch
        if [[ "${WORDY}" = "y" ]]; then
            message="${BOLD}Switching${CLEAR} to branch "
            message+="${BOLD}${featureBranch}${CLEAR} in repo ${name}"
        else
            print_dot
        fi

        command=("${SINGLE}" "${message}" \
                             git -C "${_FRIJA_HOME}/${base}" \
                             checkout "${featureBranch}")
        run "${command[@]}"

        print_debug "Setting result='${featureID}'"
        result="${featureID}"
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


function checkout_worktree()
{
    print_debug_enter "${@}"

    local base="${1}"
    local version="${2}"
    local name="${3}"

    if [[ -n "${version}" ]]; then
        # Repo should already have been cloned when we reach
        # this point. When version is non-empty this means
        # that a Git worktree should be created from the
        # cloned repo.
        worktree=$(make_destination "" "${name}" "${version}")

        print_debug "worktree='${worktree}'"
        local message=""
        local worktreePath="${_FRIJA_HOME}/${base%/*}/${worktree}"
        print_debug "worktreePath='${worktreePath}'"
        if [[ -e "${worktreePath}" ]]; then
            # Worktree has already been created
            print_newline_after_dot
            message="Git Worktree ${BOLD}'${worktree}'${CLEAR} already exist..."
            print_message "${message}"
        else
            if [[ ! -e "${_FRIJA_HOME}/${base}" ]]; then
                message="Git Worktree base repo '${base}' does not exist, "
                message+="aborting."

                print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
            fi

            local foundTag=""
            foundTag=$(git -C "${_FRIJA_HOME}/${base}" tag --list "${version}")
            print_debug "foundTag='${foundTag}'"

            if [[ "${foundTag}" == "${version}" ]]; then
                # Tag named as $version does exist; create a worktree!
                print_debug "worktree does not exist!"
                message="${BOLD}Creating${CLEAR} a Git Worktree for "
                message+="repo ${base} @ tag ${BOLD}${version}${CLEAR}..."

                command=("${SINGLE}" "${message}" \
                                     git -C "${_FRIJA_HOME}/${base}" \
                                     worktree add --detach \
                                     "../${worktree}" "${version}")
                run "${command[@]}"
            else
                message="No tag named '${BOLD}${version}${CLEAR}' found in "
                message+="repo '${BOLD}${base}${CLEAR}'.\\n\\n"
                message+="${BOLD}Please fix problem and try again, "
                message+="aborting.${CLEAR}"

                print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
            fi
        fi
    fi

    print_debug_exit
}


# source: Type of service to use when replicating, e.g. git
# uri: From where to obtain the data
# composite: Name of composite used for grouping related repos [optional]
# version: Version identifier to use, e.g. "x.y.z" [optional]
#
# NOTE: Name of destination folder is derived from uri, composite, and
# version using the function make_destination().
function replicate_data()
{
    print_debug_enter "${@}"

    local source="${1}"
    local uri="${2}"
    # Make $3 optional by having default value be an empty string
    local composite="${3:-}"
    # Make $4 optional by having default value be an empty string
    local version="${4:-}"
    # Make $5 optional by having default value be $_FRIJA_FEATURE_ID
    local featureID="${5:-${_FRIJA_FEATURE_ID}}"

    local destination=""
    local base=""
    local message=""
    local name=""

    local selectedBranch=""

    # Make command to be a local variable and an array
    declare -a command

    case "${source}" in
        git)
            if [[ "$uri" =~ $GIT_REPO_PATTERN ]]; then
                name="${BASH_REMATCH[2]:-${BASH_REMATCH[1]}}"
            else
                message="Unsupported ${BOLD}Git repo URI path${CLEAR}: "
                message+="URI is '${uri}' and pattern is "
                message+="'${GIT_REPO_PATTERN}', aborting."
                print_error "${message}" $_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS
            fi

            base=$(make_destination "${composite}" "${name}")
            print_debug "base='${base}'"
            print_debug "composite='${composite}'"
            print_debug "name='${name}'"

            if [[ -e "${_FRIJA_HOME}/${base}" ]]; then
                print_newline_after_dot
                message="Git repo ${BOLD}'${base}'${CLEAR} already exist..."
                print_message "${message}"
            else
                message="${BOLD}Cloning${CLEAR} repo ${name} "
                message+="as ${BOLD}${base}${CLEAR}"
                print_debug "message='${message}'"

                if [[ "${WORDY}" == "y" ]]; then
                    print_debug "Creating wordy command line"
                    command=("${SINGLE}" "${message}" \
                                         git -C "${_FRIJA_HOME}" \
                                         clone --progress "$uri" "$base")
                else
                    command=("${SINGLE}" "${message}" \
                                         git -C "${_FRIJA_HOME}" \
                                         clone "$uri" "$base")
                fi

                run "${command[@]}"

                # Checkout branch; feature, develop, or master in that
                # order of precedence
                selectedBranch=$(checkout_branch "${base}" "${NON_VERSION}")
                print_debug "selectedBranch='${selectedBranch}'"
            fi

            print_debug "version='${version}'"
            if [[ -n "${version}" ]] && \
                   [[ "${version}" != "${NON_VERSION}" ]]; then
                checkout_worktree "${base}" "${version}" "${name}"
            fi
            ;;
        *)
            local message="Unsupported SOURCE: '${source}' for '${uri}', "
            message+="aborting."

            print_error "${message}" $_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS
            ;;
    esac
    print_debug_exit
}


function git_find_feature_branch()
{
    print_debug_enter "${@}"

    local base="${1}"
    local featureID="${2:-${_FRIJA_FEATURE_ID}}"

    local result=""
    local branches=""

    if [[ -n "${_FRIJA_HOME}" ]]; then
        base="${_FRIJA_HOME}/${base}"
    fi

    ## Get all remote branches
    branches=$(git -C "${base}" branch --remotes | grep -v HEAD)

    # Find feature branch matching current Feature ID (signified by
    # folder name containing .frija folder). If no such feature branch
    # exist select develop, and if no such branch exist fall back to
    # develop.
    while read -r remoteBranch; do
        # Strip "origin/" prefix from each remote branch
        remoteBranch="${remoteBranch#*/}"

        # Order is not important here. What is important to note here
        # is that if we find a feature branch that starts with
        # $_FRIJA_FEATURE_ID then we break out from the while loop
        # after saving the branch name in $result.
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
        if [[ "${remoteBranch}" == "feature/${featureID}"* ]]; then
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

        local message="Could find neither a feature branch for feature "
        message+="${_FRIJA_FEATURE_ID} nor develop branch or master branch "
        message+="for repo ${repoName}."
        print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
    fi

    print_debug_exit "${result}"
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

        print_debug "verbose='${VERBOSE}', " \
                    "debug='${DEBUG}', " \
                    "remoteBranch='${remoteBranch}', " \
                    "localBranch='${localBranch}'"

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

        print_debug "  aheadCount='${aheadCount}', behindCount='${behindCount}'"

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


################################################################################
################################################################################


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
        if [[ -d "${_FRIJA_CONFIG_CACHE_PATH}" ]]; then
            # Remove all files in cache; ensure that
            # $_FRIJA_CONFIG_CACHE_PATH is non-empty using ${foo:?}
            # expansion that displays an error message if $foo is null
            # or unset.
            rm -fr "${_FRIJA_CONFIG_CACHE_PATH:?}/*"
        fi
    fi

    _frija_cleanup_function
}

# Install exit trap function that will be called when script exits
trap cleanup EXIT
