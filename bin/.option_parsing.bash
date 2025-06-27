################################################################################
#  NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
################################################################################
# This file must not contain any calls to exit unless they are guarded
# using a test on _FRIJA_IS_SOURCED ; it is non-empty when we are
# sourced, otherwise it is assigned the empty string.
#
# The reason is that if a sourced script calls exit, then the users
# shell exits which is most likely not what the user expected when for
# instance trying to complete a command...
#
# Furthermore as a general rule all functions found within this file
# (and any file it sources) should be prefixed with "frija_" or
# similar as they will be exported to the interactive Bash shell. This
# is to minimize the risk for name conflicts.
################################################################################
#  NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
################################################################################
#
# File is sourced by .core_config.bash and bootstrap scripts.


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


function ensure_boolean_option_set()
{
    if [[ -n "${2}" ]]; then
        if [[ "${2}" == "n" ]]; then
            local message="${BOLD}'${1}'${CLEAR} option must be selected!"
            print_error "${message}" $_FRIJA_EXIT_CMD_LINE_PROBLEMS
        fi
    fi
}
