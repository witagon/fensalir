#!/bin/bash

declare -A _FRIJA_SUBCOMMANDS

# List of available subcommands
_FRIJA_SUBCOMMAND_LIST=""

# Currently selected subcommand
_FRIJA_SUBCOMMAND_NAME=""


# Currently selected command. The prefix used for all sub-commands is
# "${_FENSALIR_CMD_NAME}-".
_FENSALIR_CMD_NAME=""

# Shortoptions for current command
_FRIJA_SHORTOPTS=""

# Longoptions for current command
_FRIJA_LONGOPTS=""


# Dynamic opts start with a leading '+' followed by a key, an '=', and
# a value. The Fensalir command (frija-*, fensalir-*, volla-*, ...) is
# requested to provide completion values for the key part and the
# value part via two functions;
# "_${_FENSALIR_CMD_NAME}_subcommand_dynamic_options"() and
# "_${_FENSALIR_CMD_NAME}_subcommand_dynamic_values"()
#
# These can for instance be used for completions of dynamically
# obtained things like tags that also include version numbers and
# things like country, site, and domain in their names and so on.

# Character used for dynamic options. These follow strictly after the
# ordinary options and can thus not be mixed with each other. If a
# Frija command opts to use dynamic options then these are not subject
# to getopt parsing and must follow the ordinary options (getopt will
# stop parsing options once it finds one that starts with '+').
_FRIJA_DYNAMIC_OPT_INTRO="+"

# Text used to indicate to user that there is a placeholder for
# dynamic options
_FRIJA_DYNAMIC_OPT_MARKER=" +..."

# Regexp for dynamic option marker
_FRIJA_DYNAMIC_OPT_MARKER_PATTERN="^([+][.]?[.]?[.]?)$"
#
# shellcheck disable=SC2034
declare -a _FRIJA_DYNAMIC_OPTS=()
# shellcheck disable=SC2034
declare -a _FRIJA_DYNAMIC_USED_OPTIONS=()
# shellcheck disable=SC2034
declare -A _FRIJA_DYNAMIC_OPT_INDEXES=()


declare -a _FRIJA_SHORTOPT_ARRAY=()
declare -a _FRIJA_LONGOPT_ARRAY=()
declare -a _FRIJA_OPT_TYPE=()

declare -a _FRIJA_USED_OPTIONS=()
declare -A _FRIJA_OPT_INDEXES=()

# Flags used internally to partition options into different classes
# regardless of if the option is a short or long-option to get a
# common interface instead of the two notations used by GNU getopt.
_FRIJA_NONE_TYPE="N"
_FRIJA_OPTIONAL_TYPE="O"
_FRIJA_MANDATORY_TYPE="M"


# This function dynamically redefines a set of functions that might be
# overridden by the frija subcommand implementations. However, these
# cannot be defined outside of this "meta function" as normal
# functions due to that they are then defined only once and any
# redefinitions made by the sourced subcommands linger.
#
# A script opting to not implement one of them would then inherit the
# definition from the last Frija subcommand that was TAB-completed...
#
# This "meta function" is thus intended to be called just before a
# Frija subcommand is sourced. This will reset the stage and allow the
# sourced Frija subcommand to choose which of these functions to
# override. And it also makes it possible to programmatically detect
# if one of these functions has been overridden or not.
function _frija_init_interface_functions()
{
    print_debug_enter

    # Note that due to how Bash seems to work it is neither possible
    # to redefine these functions explicitly within this function nor
    # source a file redefining them. The redefintions does not take
    # effect after the first invocation.
    #
    # What DOES work is to redefine them using eval command, that is
    # dynamically redefine them each time this function is called.

    local definition=""

    # Short options for subcommand in same notation as getopt command
    # uses; expected to be overridden by subcommand.
    definition="function _${_FENSALIR_CMD_NAME}_subcommand_shortoptions() "
    definition+="{ "
    definition+="print_debug_enter 'DEFAULT IMPLEMENTATION'; "
    definition+="print_debug_exit  'DEFAULT IMPLEMENTATION'; "
    definition+="echo ''; "
    definition+="}"
    eval "${definition}"


    # Long options for subcommand in same notation as getopt command uses;
    # expected to be overridden by subcommand.
    definition="function _${_FENSALIR_CMD_NAME}_subcommand_longoptions() "
    definition+="{ "
    definition+="print_debug_enter 'DEFAULT IMPLEMENTATION'; "
    definition+="print_debug_exit  'DEFAULT IMPLEMENTATION'; "
    definition+="echo ''; "
    definition+="}"
    eval "${definition}"


    # Return available completions for given option for a subcommand.
    #
    # $1 contain name of option to get available values for; expected to
    # be overridden by subcommand.
    definition="function _${_FENSALIR_CMD_NAME}_subcommand_option_values() "
    definition+="{ "
    definition+="print_debug_enter 'DEFAULT IMPLEMENTATION'; "
    definition+="print_debug_exit  'DEFAULT IMPLEMENTATION'; "
    definition+="echo ''; "
    definition+="}"
    eval "${definition}"


    # Return available dynamic options, not to be mixed up with short or
    # long options which are static/fixed for a given subcommand.
    definition="function _${_FENSALIR_CMD_NAME}_subcommand_dynamic_options() "
    definition+="{ "
    definition+="print_debug_enter 'DEFAULT IMPLEMENTATION'; "
    definition+="print_debug_exit  'DEFAULT IMPLEMENTATION'; "
    definition+="echo ''; "
    definition+="}"
    eval "${definition}"


    # Return available dynamic option completions for the given dynamic
    # option, not to be mixed up with short or long options which are
    # static/fixed for a given subcommand.
    definition="function _${_FENSALIR_CMD_NAME}_dynamic_option_values() "
    definition+="{ "
    definition+="print_debug_enter 'DEFAULT IMPLEMENTATION'; "
    definition+="print_debug_exit  'DEFAULT IMPLEMENTATION'; "
    definition+="echo ''; "
    definition+="}"
    eval "${definition}"

    print_debug_exit
}

################################################################################
################################################################################

function _frija_subcommand_has_dynamic_completion()
{
    # RETURN trap is executed before execution resumes after a shell
    # function returns. This RETURN trap restores the extdebug
    # (extended debugging mode)
    #
    # shellcheck disable=SC2064
    trap "$(shopt -p extdebug)" RETURN

    # Enable extended debugging mode to be able to find name of file
    # defining a function
    shopt -s extdebug

    local currentPath=""
    currentPath=$(declare -F "${FUNCNAME[0]}")
    currentPath="${currentPath#*/}"

    local sourcePath=""
    sourcePath=$(declare -F "_${_FENSALIR_CMD_NAME}_subcommand_dynamic_options")
    sourcePath="${sourcePath#*/}"

    [[ "${sourcePath}" != "${currentPath}" ]]
    # return command without any argument return the return code of
    # the previous statement; in this case the string comparison test
    # above
    return
}


# $1 contains name of option to get available values for.
function _frija_internal_option_values()
{
    print_debug_enter "$@"
    local optionName="${1}"
    local optionValue="${2:-}"
    local result=""

    # Generate name of function to call to get list of available
    # completions for given option and option value. Note that this
    # function might not exist in the worst case scenario, it is only
    # assumed to exist.
    local optionFunction=""
    if [[ -n "${_FRIJA_SUBCOMMAND_NAME}" ]]; then
        # Name of function returning subcommand option values
        optionFunction="_${_FENSALIR_CMD_NAME}_subcommand_option_values"
    else
        # Name of function returning command option values
        optionFunction="_${_FENSALIR_CMD_NAME}_command_option_values"
    fi

    print_debug "optionFunction='${optionFunction}'"
    # Check if the created function name exist and if so call it. Note
    # that any output from declare command must be redirected to
    # /dev/null, otherwise it will polute the return value from this
    # function.
    if declare -F "${optionFunction}" 1>&2 >/dev/null; then
        result=$("${optionFunction}" "${optionName}" "${optionValue}")
        print_debug "result='${result}'"
    fi

    print_debug "result='${result}'"
    print_debug_exit "${result}"
    # Return result
    echo "${result}"
}


function _frija_update_subcommands()
{
    print_debug_enter

    # We want the expansion of the function call to expand BEFORE trap
    # executes to be able to restore it to its original value.
    #
    # shellcheck disable=SC2064
    trap "$(frija_restore_globignore_expression)" RETURN

    # Clear Frija command interface functions used for TAB-completion
    _frija_init_interface_functions

    # Clear _FRIJA_SUBCOMMANDS so it does not contain any stale information
    _FRIJA_SUBCOMMANDS=()

    # Exclude all files that contain at least one "." after the
    # prefix, e.g. exclude all Emacs backup files
    GLOBIGNORE="${_FENSALIR_CMD_NAME}-*.*"

    declare -a commands
    # Glob-expand path to get all files starting with
    # "${_FENSALIR_CMD_NAME}-"; these are the subcommands!
    commands=("${_FENSALIR_HOME}/${_FENSALIR_CMD_NAME}-"*)

    # Remove path prefix from each element in array
    commands=("${commands[@]##${_FENSALIR_HOME}/}")

    local subcommand=""
    local name=""
    declare -i index
    # Iterate over keys in array commands, i.e. '!' forces expansion
    # of array indices for all elements in the array.
    for index in "${!commands[@]}"; do
        subcommand="${commands[$index]}"
        # Remove "${_FENSALIR_CMD_NAME}-" prefix from command name
        name="${subcommand//${_FENSALIR_CMD_NAME}-/}"
        # Add name and subcommand to associative array _FRIJA_SUBCOMMANDS
        _FRIJA_SUBCOMMANDS["${name}"]="${subcommand}"
    done

    # Finally update _FRIJA_SUBCOMMAND_LIST with identified subcommands
    _FRIJA_SUBCOMMAND_LIST="${!_FRIJA_SUBCOMMANDS[*]}"

    print_debug_exit
}


# shellcheck disable=SC2120
function _frija_update_subcommand_state()
{
    print_debug_enter "$@"

    local override="${1:-}"

    declare -a currentItems=()

    if [[ -n "${override}" ]];then
        currentItems=("${override}")
    else
        if (( ${#COMP_WORDS[@]:-0} > 0 )); then
           currentItems=("${COMP_WORDS[@]:1}")
        fi
    fi

    # TODO: Convert [[ ... ]] to (( ... ))
    if [[ "${#currentItems[@]:-0}" -eq 0 ]]; then
        # No need to iterate through an empty array...
        return
    fi

    if [[ "${currentItems[-1]}" == "" ]]; then
        unset "currentItems[${#currentItems[@]}-1]"
    fi

    # Search through current command line options to see if there is
    # one that is not an option and that is included in
    # _FRIJA_SUBCOMANDS. If so, then we should switch to the
    # sub-commands options instead of the base command options.
    local item=""
    local option=""
    local subcommand=""

    _FRIJA_SUBCOMMAND_NAME=""

    declare -i frijaCompletionIndex=0
    for frijaCompletionIndex in "${!currentItems[@]:-}"; do
        item="${currentItems[${frijaCompletionIndex}]}"

        # Extract just the option
        [[ "${item}" =~ ^(-[^-]|--[^=]+).*$ ]]
        option="${BASH_REMATCH[1]:-}"

        if [[ "${item}" != "" ]] && [[ "${option}" == "" ]]; then
            # We have a candidate for a subcommand

            # Check if we have a match (whether $item is a registered
            # subcommand or not)
            subcommand="${_FRIJA_SUBCOMMANDS[${item}]:-}"
            if [[ -n "${subcommand}" ]]; then
                # Save current subcommand name
                _FRIJA_SUBCOMMAND_NAME="${item}"

                # No need for subcommand-list any more
                _FRIJA_SUBCOMMAND_LIST=""

                local scriptName="${_FENSALIR_CMD_NAME}-"
                scriptName+="${_FRIJA_SUBCOMMAND_NAME}"
                print_debug "scriptName='${scriptName}'"

                # Source subcommand to bring its functions into the
                # environment. Note that we are praying very hard that
                # the sourced file does not use any variable named
                # 'frijaCompletionIndex' as that would wreck havoc on
                # our loop (possibly causing an infinite loop or a
                # runtime error).
                #
                # shellcheck source=./.core_config.bash
                source "${_FENSALIR_HOME}/${scriptName}"

                # Dynamically call functions where the name is
                # dynamically built from strings. One function name is
                # for obtaining the shortoptions and one for the
                # corresponding longoptions. Both of these functions
                # are assumed to start with the same name prefix
                # (stored in $commandNamePrefix), e.g.
                # "_frija_subcommand" or "_fensalir_subcommand".
                local commandNamePrefix="_${_FENSALIR_CMD_NAME}_subcommand"
                _FRIJA_SHORTOPTS="$(${commandNamePrefix}_shortoptions)"
                _FRIJA_LONGOPTS="$(${commandNamePrefix}_longoptions)"

                print_debug "_FRIJA_SHORTOPTS='${_FRIJA_SHORTOPTS}'"
                print_debug "_FRIJA_LONGOPTS='${_FRIJA_LONGOPTS}'"

                # Exit from for-loop
                break
            fi
        fi
    done

    print_debug_exit
}


function _frija_filter_options()
{
    local cur
    local prev

    # Last index of $COMP_WORDS array to retain before eliminating
    # already used options.
    declare -i lastIndex
    lastIndex="${COMP_CWORD}"

    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Calculate last index to retain in $COMP_WORDS array; three cases
    # to consider:
    #
    # 1) Current word is '=', i.e. argument for a long option should
    #    be entered by user
    #
    # 2) Previous word is '=', i.e. user is (possibly) completing
    #    argument for long option
    #
    # 3) Current word is a non-empty string, i.e. user is (possibly)
    #   completing option
    #
    # In all above cases the last portions of $COMP_WORDS array should
    # be left out when filtering. By how much depends on the case,
    # since for instance '=' used for long option argument is a
    # separate "word" for the completion system that has to be removed
    # at the end.
    if [[ "${cur}" == "=" ]]; then
        lastIndex=$(( lastIndex - 2 ))  # Arithmetic expression
    elif [[ "${prev}" == "=" ]]; then
        lastIndex=$(( lastIndex - 3 ))
    elif [[ -n "${cur}" ]]; then
        lastIndex=$(( lastIndex - 1 ))
    fi

    declare -a currentItems

    if [[ "${lastIndex}" -lt 1 ]]; then
        # "Everything" should be removed from $COMP_WORDS array.
        currentItems=()
    else
        # Slice a portion from $COMP_WORDS array so that both the
        # command name is removed AND a suitable part of the end is
        # also (possibly) removed depending on above cases.
        currentItems=("${COMP_WORDS[@]:1:${lastIndex}}")
    fi

    # Clear array containing indexes of used options so we then can
    # fill it with those actually used. Once that is done we can
    # filter out those that are not used. :)
    _FRIJA_USED_OPTIONS=()

    local item=""
    local pos=""
    local filteredItems=""

    declare -i index
    for index in "${!currentItems[@]}"; do
        item="${currentItems[${index}]}"
        # Extract just the option
        [[ "${item}" =~ ^(-[^-]|--[^=]+).*$ ]]
        item="${BASH_REMATCH[1]:-}"

        if [[ -n "${item}" ]]; then
            pos="${_FRIJA_OPT_INDEXES[${item}]}"
            type="${_FRIJA_OPT_TYPE[pos]}"

            if [[ -n "${pos}" ]]; then
                _FRIJA_USED_OPTIONS["${pos}"]="${pos}"
            else
                _FRIJA_USED_OPTIONS["${pos}"]=""
            fi
        fi
    done

    for index in "${!_FRIJA_SHORTOPT_ARRAY[@]}"; do
        pos="${_FRIJA_USED_OPTIONS[${index}]:-}"
        if [[ "${pos}" == "" ]]; then
            # Add from both shortoptions and longoptions arrays
            filteredItems+=" ${_FRIJA_SHORTOPT_ARRAY[${index}]}"
            filteredItems+=" ${_FRIJA_LONGOPT_ARRAY[${index}]:-}"
        fi
    done

    # When there are more items in $_FRIJA_LONGOPT_ARRAY[@] than in
    # $_FRIJA_SHORTOPT_ARRAY[@] and they have not already been added
    # then add them. Note that this expression depend on the index
    # variable from above for-loop!
    for item in "${_FRIJA_LONGOPT_ARRAY[@]:index+1}"; do
        (( index++ ))
        pos="${_FRIJA_USED_OPTIONS[${index}]:-}"
        if [[ "${pos}" == "" ]]; then
            # Add only from longoptions array
            filteredItems+=" ${_FRIJA_LONGOPT_ARRAY[${index}]:-}"
        fi
    done

    if [[ -n "${_FRIJA_DYNAMIC_OPT}" ]]; then
        filteredItems+=" ${_FRIJA_DYNAMIC_OPT}"
    fi

    echo "${filteredItems}"
}


function _frija_set_type()
{
    print_debug_enter "$@"

    declare -i index="${1}"
    local type="${2}"

    local value="${_FRIJA_OPT_TYPE[index]:-}"
    declare -i returnCode=0

    if [[ "${value}" == "" ]]; then
        _FRIJA_OPT_TYPE[$index]="${type}"
    elif [[ "${type}" != "${value}" ]]; then
        # Ambigious option types (${value} does not match ${type})
        # This will happen if for instance there is a mismatch between
        # short and long options. That is there might be more long
        # options than short options, but all short otions must match
        # 1:1 with corresponding long options.
        returnCode=1
    fi

    print_debug_exit
    return ${returnCode}
}


function _frija_set_opt_index()
{
    print_debug_enter "$@"

    local opt="${1}"
    declare -i index="${2}"

    local value="${_FRIJA_OPT_INDEXES[${opt}]:-}"
    declare -i returnCode=0

    if [[ "${value}" == "" ]]; then
        _FRIJA_OPT_INDEXES["${opt}"]=$index
    else
        # Duplicate options
        returnCode=1
    fi

    print_debug_exit
    return ${returnCode}
}


function _frija_extract_options()
{
    print_debug_enter "$@"

    local optionList="${1}"
    local prefix="${2}"
    local result=""

    # shellcheck disable=SC2206
    declare -a optionArray=(${optionList//,/ })
    print_debug_array optionArray

    local type=""
    local option=""
    declare -i index=0

    # Iterate through $optionList and determine kind of option, i.e.
    # if it has an argument and if so wheter it is an optional or
    # mandatory argument. Same notation as getopt uses is expected,
    # i.e. option suffix determine kind of option
    #
    # ::  Optional option argument
    #  :  Mandatory option argument
    #     No option argument (no suffix)
    for index in "${!optionArray[@]}"; do
        option="${optionArray[${index}]}"
        print_debug "${index}: option='${option}'"

        if [[ -n "${option}" ]]; then
            [[ "${option}" =~ ^([^:]+)(:*)$ ]]
            option="${BASH_REMATCH[1]:-}"
            type="${BASH_REMATCH[2]:-}"

            print_debug "After regex: option='${option}'"
            print_debug "After regex: type='${type}'"

            case "${type}" in
                "::")
                    type="${_FRIJA_OPTIONAL_TYPE}"
                    ;;
                ":")
                    type="${_FRIJA_MANDATORY_TYPE}"
                    ;;
                *)
                    type="${_FRIJA_NONE_TYPE}"
                    ;;
            esac
            print_debug "After case: type='${type}'"

            _frija_set_type $index "${type}"
            # shellcheck disable=SC2181
            [[ $? -eq 0 ]] || return 1

            _frija_set_opt_index "${prefix}${option}" $index
            # shellcheck disable=SC2181
            [[ $? -eq 0 ]] || return 2

            if [[ "${prefix}" == "--" ]]; then
                _FRIJA_LONGOPT_ARRAY["${index}"]="${prefix}${option}"
            elif [[ "${prefix}" == "-" ]]; then
                _FRIJA_SHORTOPT_ARRAY["${index}"]="${prefix}${option}"
            fi
        fi
    done

    print_debug_exit
}


function _frija_convert_shortopts()
{
    local options="${1}"
    local validFound="n"
    local result=""

    # Iterate through short options in getopt format, i.e.
    #
    # ab:cd::efgh
    #
    # where single letter option b have a mandatory option argument
    # and single letter option d has an optional option argument.
    #
    # This format is converted to a hybrid variant between the short
    # and long getopt option formats where a ',' is inserted between
    # each short-option. Example above would then be converted to
    #
    # a,b:,c,d::,e,f,g,h
    #
    # The benefit of this is that common code can be used for further
    # processing of the option list.
    while read -r -n 1 current; do
        if [[ "${current}" == "" ]]; then
            # Reached end of input string
            continue
        fi

        # Skip the colon test until first valid character found to
        # avoid getting a comma before any colons
        if [[ "${validFound}" == "y" ]]; then
            if [[ "${current}" != ":" ]]; then
                result+=","
            fi
        fi

        # Skip any initial +-
        if [[ "${current}" =~ [^+-] ]]; then
            result+="${current}"
            validFound="y"
        else
            validFound="n"
        fi
    done <<< "${options}"

    echo "${result}"
}


function _frija_initialize()
{
    print_debug_enter
    # Assume we should use base commands options
    _FRIJA_SHORTOPTS="$(_frija_shortoptions)"
    _FRIJA_LONGOPTS="$(_frija_longoptions)"

    # Reset global array variables
    _FRIJA_SHORTOPT_ARRAY=()
    _FRIJA_LONGOPT_ARRAY=()
    _FRIJA_OPT_TYPE=()
    _FRIJA_USED_OPTIONS=()

    # Reset global associative array variable
    _FRIJA_OPT_INDEXES=()

    # If we happen to be in a subcommand, then these functions will
    # update our initial state, for instance re-initialize
    # $_FRIJA_SHORTOPTS and $_FRIJA_LONGOPTS
    _frija_update_subcommands
    # shellcheck disable=SC2119
    _frija_update_subcommand_state

    # Initialize global array and associative array variables
    local optionList

    print_debug "Before call to _frija_convert_shortopts ${_FRIJA_SHORTOPTS}"
    optionList=$(_frija_convert_shortopts "${_FRIJA_SHORTOPTS}")
    # shellcheck disable=SC2181
    [[ $? -eq 0 ]] || return 1

    print_debug "Before call to _frija_extract_options ${optionList} -"
    _frija_extract_options "${optionList}" "-"
    # shellcheck disable=SC2181
    [[ $? -eq 0 ]] || return 1

    print_debug "Before call to _frija_extract_options ${_FRIJA_LONGOPTS} --"
    _frija_extract_options "${_FRIJA_LONGOPTS}" "--"
    # shellcheck disable=SC2181
    [[ $? -eq 0 ]] || return 1


    # If subcommand has overridden the default implementation of
    # _${_FENSALIR_CMD_NAME}_subcommand_option_values() function, then
    # add special marker indicating that there is also something
    # starting with $_FRIJA_DYNAMIC_OPT_INTRO
    if _frija_subcommand_has_dynamic_completion; then
        _FRIJA_DYNAMIC_OPT=" ${_FRIJA_DYNAMIC_OPT_MARKER}"
    else
        _FRIJA_DYNAMIC_OPT=""
    fi

    print_debug_exit
}


function _frija_mandatory_option_completion()
{
    print_debug_enter
    if [[ "${cur}" == "=" ]] || [[ "${prev}" == "=" ]] || \
           [[ -n "${prefix}" ]]; then
        local valueList
        valueList=$(_frija_internal_option_values "${option}" "${value}")
        print_debug "valueList='${valueList}'"

        # Note: "<(...)" is Process Substitution in Bash, hence "<
        # <(...)" uses redirect in combination with Process
        # Substitution.
        #
        # Note '--' separates list of options and current value to be
        # completed
        mapfile -t COMPREPLY < \
                <(compgen -P "${prefix}" -W "${valueList}" -- "${value}")

        if [[ "${COMPREPLY[*]}" == "${prefix}${value}" ]]; then
            # Single option has matched, move on to next by telling
            # complete to add a space.
            compopt +o nospace
        fi
    else
        print_debug "Adding '=' to current option"
        # Add a '=' to current option so user can add an argument
        # value.
        #
        # Note '--' separates list of options and current value to be
        # completed
        mapfile -t COMPREPLY < <(compgen -W "${cur}=" -- "${cur}")
    fi
    print_debug_exit
}


function _frija_optional_option_completion()
{
    local cur="${1}"
    local prev="${2}"
    local prefix="${3}"
    local option="${4}"
    local value="${5}"

    if [[ "${cur}" == "=" ]] || [[ "${prev}" == "=" ]] \
           || [[ -n "${prefix}" ]]; then
        local valueList
        valueList=$(_frija_internal_option_values "${option}" "${value}")

        # Use mapfile to safely get output from compgen command into
        # COMPREPLY array variable.
        #
        # Note: The notation "<(...)" is called process substitution
        # and means that the output from the enclosed command appear
        # like a file. This is then redirected into the builtin
        # command mapfile using ordinary redirection.
        #
        # Note '--' separates list of options and current value to be
        # completed
        mapfile -t COMPREPLY < \
                <(compgen -P "${prefix}" -W "${valueList}"  -- "${value}")

        if [[ "${COMPREPLY[*]}" == "${prefix}${value}" ]]; then
            # Single option has matched, move on to next by telling
            # complete to add a space.
            compopt +o nospace
        fi
    else
        # Add a '=' to current option so user can add an argument
        # value.
        #
        # Note '--' separates list of options and current value to be
        # completed
        mapfile -t COMPREPLY < <(compgen -W "${cur} ${cur}=" -- "${value}")
    fi
}

function _frija_complete_non_option_parameter()
{
    print_debug_enter "${@}"

    local cur="${1}"
    local prev="${2}"

    print_debug_array COMP_WORDS
    print_debug "cur='${cur}'"
    print_debug "prev='${prev}'"
    print_debug "_FRIJA_DYNAMIC_OPT_MARKER_PATTERN='${_FRIJA_DYNAMIC_OPT_MARKER_PATTERN}'"

    # Pattern matching the option value we receive from the completion
    # engine; that is prefixed with a '+' and possibly suffixed with
    # an '='. This regex can then be used to extract the option
    # without any of these embellishments
    local NON_OPTION_PATTERN="^[+]([^=]+)=?$"

    if [[ "${cur}" =~ ${_FRIJA_DYNAMIC_OPT_MARKER_PATTERN} ]]; then
        # A partial or a complete $_FRIJA_DYNAMIC_OPT_MARKER (1-3
        # dots after the '+')

        local valueList="a/b/c d/e/f a/e/f"
        print_debug "valueList='${valueList}'"
        local completions=""
        completions=$(compgen -P "+" -S "=" -W "${valueList}" -- "${cur}")
        print_debug "completions='${completions}'"

        # Note '--' separates list of options and current value to be
        # completed. Use Process Substitution to run the command
        # 'compgen'; connect mapfile command with compgen process via
        # named pipes
        mapfile -t COMPREPLY < <(compgen -P "+" -S "=" -W "${valueList}" -- "")
        print_debug_array "COMPREPLY"

        local message="\\n"
        message+="Entering non-option parameter mode. Please press TAB again"
        if [[ "${cur}" == "${_FRIJA_DYNAMIC_OPT_INTRO}" ]]; then
            message+="."
        else
            message+=" ${BOLD}twice${CLEAR}."
        fi
        print_message "${ITALIC}${message}${CLEAR}"
    elif [[ "${cur}" =~ ${NON_OPTION_PATTERN} ]]; then
        # Something that might be a key-value pair. Further
        # investigation needed to conclude what we have infront of
        # us.
        local valueList="a/b/c d/e/f a/e/f"
        local nonOption="${BASH_REMATCH[1]}"

        print_message "Something else to complete"
        print_debug "Something else to complete"

        # Note '--' separates list of options and current value to be
        # completed. Use Process Substitution to run the command
        # 'compgen'; connect mapfile command with compgen process via
        # named pipes
        mapfile -t COMPREPLY < <(compgen -P "+" \
                                         -S "=" \
                                         -W "${valueList}" -- "${nonOption}")
        print_debug_array "COMPREPLY"
    fi

    print_debug_exit
}


# Main entry point for completion of Frija commands
function _frija_completion_initialization()
{
    print_debug_enter

    _frija_initialize

    local cur=""
    local prev=""
    local opts=""
    local index=""
    local type=""
    local option=""

    # Global variable COMPREPLY hold an array of completion results,
    # initialize it to an empty array
    COMPREPLY=()

    # $COMP_WORDS is an array of current command line items where for
    # instance any '=' are stored as separate words. $COMP_CWORD is
    # current index into this array.
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    print_debug "cur='${cur}'  prev='${prev}'"
    print_debug "COMP_POINT='${COMP_POINT}'"
    print_debug "COMP_LINE='${COMP_LINE}'"


    if [[ "${COMP_LINE}" == *" ${_FRIJA_DYNAMIC_OPT_INTRO}"* ]]; then
        # User has opened the box of non-option parameters. That is,
        # when GNU getopt() parses the command line it stops parsing
        # if a '+' is found and treats whatever remains on the command
        # line as non-option parameters. Hence introducing a '+' on
        # the command line must also toggle the mode of operation for
        # TAB-completion.
        _frija_complete_non_option_parameter "${cur}" "${prev}"

        return 0
    fi

    # Find out which options should remain as "completable" after
    # parsing current command line; assumption is that no option may
    # be repeated, that short and long options are counted as "same",
    # and that user may use any combination of short and long options
    # (except for repeating).
    opts=$(_frija_filter_options)

    # $_FRIJA_SUBCOMMAND_NAME hold any current subcommand; is empty
    # string when only in frija base command
    if [[ -z "${_FRIJA_SUBCOMMAND_NAME}" ]]; then
        # Append subcommand names to valid completions
        opts+=" ${_FRIJA_SUBCOMMAND_LIST}"
    fi

    # Markers for current state
    local short="s"
    local long="l"
    local command="c"

    local value=""    # Current option completion value
    local variant=""  # Holds one of the markers above

    # Holds prefix to append to all completions, that is when
    # completing short option arguments the option must be used as a
    # prefix to the completion alternatives.
    local prefix=""

    if [[ -n "${cur}" ]]; then
        # Find out which option we are dealing with
        if [[ "${prev}" == "=" ]] && [[ -n "${cur}" ]]; then
            option="${COMP_WORDS[COMP_CWORD-2]}"
        elif [[ "${cur}" == "=" ]]; then
            option="${prev}"
        else
            option="${cur}"
        fi
        print_debug "option='${option}'"

        # Detect if it is a short, long, or no option
        if [[ "${option}" =~ ^(-[^-])(.*)$ ]]; then
            # Short option detected
            option="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            variant="${short}"
            prefix="${option}"
        elif [[ "${option}" =~ ^--(.*)$ ]]; then
            # Long option detected
            if [[ "${prev}" == "=" ]]; then
                value="${cur}"
            fi
            variant="${long}"
        else
            variant="${command}"
        fi
        print_debug "variant='${variant}'"

        if [[ -n "${option}" ]]; then
            print_debug "option='${option:-}'"
            print_debug_array _FRIJA_OPT_INDEXES

            # If we have an option, try to look it up in our
            # associative array to get an index for it. This index
            # gives us information regarding whether it have a
            # mandatory argument, an optional argument, or no argument
            # at all.
            #
            # Note that this might not always succeed, since it might
            # be a partially completed option.
            index="${_FRIJA_OPT_INDEXES[$option]:-}"
        fi
        print_debug "index='${index:-}'"

        # Ensure that both the identified option is among the allowed
        # options AND that the index returned from the search is a
        # non-empty string.
        if [[ "${opts:-}" == *"${option:-}"* ]] && [[ -n "${index:-}" ]]; then
            type="${_FRIJA_OPT_TYPE[index]:-}"
            print_debug "type='${type:-}'"

            # From Bash manual: "Tell readline not to append a space
            # (the default) to words completed at the end of the line."
            compopt -o nospace
            case "${type:-}" in
                # Case alternatives stored in variables

                "${_FRIJA_OPTIONAL_TYPE}")
                    # Optional type alternative
                    print_debug "Optional type"
                    _frija_optional_option_completion \
                        "${cur}" "${prev}" "${prefix}" "${option}" "${value}"
                    return 0
                    ;;
                "${_FRIJA_MANDATORY_TYPE}")
                    # Mandatory type alternative
                    print_debug "Mandatory type"
                    _frija_mandatory_option_completion \
                        "${cur}" "${prev}" "${prefix}" "${option}" "${value}"
                    return 0
                    ;;
                # Neither optional nor mandatory type
                *)
                    # Negating nospace, i.e. space is added after option
                    compopt +o nospace

                    print_debug "Neither optional nor mandatory type"
                    local compresult=""

                    # Note '--' separates list of options and current
                    # value to be completed
                    compresult=$(compgen -W "${cur}" -- "${cur}")
                    print_debug "compgen: '${compresult}'"

                    # Note '--' separates list of options and current
                    # value to be completed
                    mapfile -t COMPREPLY < <(compgen -W "${cur}" -- "${cur}")
                    return 0
                    ;;
            esac
        elif [[ "${prev}" == "=" ]]; then
            # Negating nospace, i.e. space is added after option
            compopt +o nospace
            print_debug "Found '=', completing value part ('${cur}')"

            # Note '--' separates list of options and current value to
            # be completed
            mapfile -t COMPREPLY < <(compgen -W "${cur}" -- "${cur}")
            print_debug_array "COMPREPLY"
            return 0
        fi
    fi

    if [[ "${variant}" == "${command}" ]]; then
        # Subcommand name has been completed, add space
        print_debug "Subcommand name has been completed, add space"
        compopt +o nospace
    fi

    print_debug "opts='${opts}'"
    print_debug "cur='${cur}'"
    mapfile -t COMPREPLY < <(compgen -W "${opts}" -- "${cur}")
    print_debug_array "COMPREPLY"

    if [[ "${#COMPREPLY[@]}" -eq 1 ]]; then
        _frija_update_subcommand_state "${COMPREPLY[*]}"
    elif [[ "${#COMPREPLY[@]}" -eq 0 ]] && \
             [[ "${option}" == "${_FRIJA_SUBCOMMAND_NAME}" ]]; then
        print_debug "Redoing command completion; subcommand name identified"
        # Redo command completion since we have now identified that
        # last option is a subcommand name and we want to ensure there
        # is a space after the command name...
        #
        # Note '--' separates list of options and current value to be
        # completed
        mapfile -t COMPREPLY < <(compgen -W "${option}" -- "${option}")
        print_debug_array "COMPREPLY"
    fi

    print_debug_exit
}


function _frija()
{
    print_debug_enter

    # Set name of currently called function. Other functions might
    # depend on this value. As Bash uses call-by-name we can have it
    # as a local variable that is reachable through scope rules.
    local _FENSALIR_CMD_NAME="${FUNCNAME[0]}"

    # Remove initial '_' from variable value
    _FENSALIR_CMD_NAME="${_FENSALIR_CMD_NAME#_}"

    _frija_completion_initialization
    #echo "_frija: _FENSALIR_CMD_NAME='${_FENSALIR_CMD_NAME}'" 1>&2

    print_debug_exit
    return 0
}


function _fensalir()
{
    print_debug_enter

    # Set name of currently called function. Other functions might
    # depend on this value. As Bash uses call-by-name we can have it
    # as a local variable that is reachable through scope rules.
    local _FENSALIR_CMD_NAME="${FUNCNAME[0]}"

    # Remove initial '_' from variable value
    _FENSALIR_CMD_NAME="${_FENSALIR_CMD_NAME#_}"

    _frija_completion_initialization
    #echo "_fensalir: _FENSALIR_CMD_NAME='${_FENSALIR_CMD_NAME}'" 1>&2

    print_debug_exit
    return 0
}

complete -o nospace -F _frija frija
complete -o nospace -F _fensalir fensalir
