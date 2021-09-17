#!/bin/bash

declare -A _FRIJA_SUBCOMMANDS

# List of available subcommands
_FRIJA_SUBCOMMAND_LIST=""

# Currently selected subcommand
_FRIJA_SUBCOMMAND_NAME=""


_FRIJA_SHORTOPTS=""
_FRIJA_LONGOPTS=""

declare -a _FRIJA_SHORTOPT_ARRAY
declare -a _FRIJA_LONGOPT_ARRAY
declare -a _FRIJA_OPT_TYPE

declare -a _FRIJA_USED_OPTIONS
declare -A _FRIJA_OPT_INDEXES

_FRIJA_NONE_TYPE="N"
_FRIJA_OPTIONAL_TYPE="O"
_FRIJA_MANDATORY_TYPE="M"


# Short options for subcommand in same notation as getopt command
# uses; expected to be overridden by subcommand.
#
# Default implementation
function _frija_subcommand_shortoptions()
{
    echo ""
}


# Long options for subcommand in same notation as getopt command uses;
# expected to be overridden by subcommand.
#
# Default implementation
function _frija_subcommand_longoptions()
{
    echo ""
}


# $1 contains name of option to get available values for; expected to
# be overridden by subcommand.
#
# Default implementation!
function _frija_subcommand_option_values()
{
    echo ""
}


# $1 contains name of option to get available values for; expected to
# be overridden by subcommand.
#
# Default implementation!
function _frija_command_option_values()
{
    echo ""
}


# $1 contains name of option to get available values for.
function _frija_internal_option_values()
{
    local result

    if [[ -n "${_FRIJA_SUBCOMMAND_NAME}" ]]; then
        # Subcommand option values
        result=$(_frija_subcommand_option_values "${1}")
    else
        # Command option values
        result=$(_frija_command_option_values "${1}")
    fi

    # Return result
    echo "${result}"
}


function _frija_update_subcommands()
{
    # Clear _FRIJA_SUBCOMMANDS so it does not contain any stale information
    _FRIJA_SUBCOMMANDS=()

    # Exclude all files that contain at least one "." after the
    # prefix, e.g. exclude all Emacs backup files
    GLOBIGNORE="frija-*.*"

    declare -a commands
    # Glob-expand path to get all files starting with "frija-"; these
    # are the subcommands!
    commands=("${METADATATOOLS_HOME}"/frija-*)

    # Remove path prefix from each element in array
    commands=("${commands[@]##${METADATATOOLS_HOME}/}")

    local subcommand=""
    local name=""
    declare -i index
    # Iterate over keys in array commands, i.e. '!' forces expansion
    # of array indices for all elements in the array.
    for index in "${!commands[@]}"; do
        subcommand="${commands[$index]}"
        # Remove "frija-" prefix from command name
        name="${subcommand//frija-/}"
        # Add name and subcommand to associative array _FRIJA_SUBCOMMANDS
        _FRIJA_SUBCOMMANDS["${name}"]="${subcommand}"
    done

    # Finally update _FRIJA_SUBCOMMAND_LIST with identified subcommands
    _FRIJA_SUBCOMMAND_LIST="${!_FRIJA_SUBCOMMANDS[*]}"
}


function _frija_update_subcommand_state()
{
    local override="${1:-}"

    declare -a currentItems
    if [[ -n "${override}" ]];then
        currentItems=("${override}")
    else
        currentItems=("${COMP_WORDS[@]:1}")
    fi

    if [[ "${currentItems[-1]}" == "" ]]; then
        unset "currentItems[${#currentItems[@]}-1]"
    fi

    # Search through current command line options to see if there is
    # one that is not an option and that is included in
    # _FRIJA_SUBCOMANDS. If so, then we should switch to the
    # sub-commands options instead of the base command options.
    declare -i index
    local item=""
    local option=""
    local subcommand=""

    _FRIJA_SUBCOMMAND_NAME=""
    if [[ "${#currentItems[@]}" -eq 0 ]]; then
        # No need to iterate through an empty array...
        return
    fi

    for index in "${!currentItems[@]}"; do
        item="${currentItems[${index}]}"

        # Extract just the option
        [[ "${item}" =~ ^(-[^-]|--[^=]+).*$ ]]
        option="${BASH_REMATCH[1]}"

        if [[ "${item}" != "" ]] && [[ "${option}" == "" ]]; then
            # We have a candidate for a subcommand

            # Check if we have a match (whether $item is a registered
            # subcommand or not)
            subcommand="${_FRIJA_SUBCOMMANDS[${item}]}"
            if [[ -n "${subcommand}" ]]; then
                # Save current subcommand name
                _FRIJA_SUBCOMMAND_NAME="${item}"

                # No need for subcommand-list any more
                _FRIJA_SUBCOMMAND_LIST=""

                # Source subcommand to bring its functions into the environment
                # shellcheck source=./.core_config.bash
                source "${METADATATOOLS_HOME}/frija-${_FRIJA_SUBCOMMAND_NAME}"

                _FRIJA_SHORTOPTS="$(_frija_subcommand_shortoptions)"
                _FRIJA_LONGOPTS="$(_frija_subcommand_longoptions)"

                # Exit from for-loop
                break
            fi
        fi
    done
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
        item="${BASH_REMATCH[1]}"

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
        pos="${_FRIJA_USED_OPTIONS[${index}]}"
        if [[ "${pos}" == "" ]]; then
            filteredItems+=" ${_FRIJA_SHORTOPT_ARRAY[${index}]}"
            filteredItems+=" ${_FRIJA_LONGOPT_ARRAY[${index}]}"
        fi
    done

    echo "${filteredItems}"
}


function _frija_set_type()
{
    declare -i index
    index="${1}"
    local type="${2}"
    local value="${_FRIJA_OPT_TYPE[index]}"

    if [[ "${value}" == "" ]]; then
        _FRIJA_OPT_TYPE[$index]="${type}"
    elif [[ "${type}" != "${value}" ]]; then
        # Ambigious option types (${value} does not match ${type})
        return 1
    fi
}


function _frija_set_opt_index()
{
    local opt="${1}"
    declare -i index
    index="${2}"

    local value="${_FRIJA_OPT_INDEXES[${opt}]}"

    if [[ "${value}" == "" ]]; then
        _FRIJA_OPT_INDEXES["${opt}"]=$index
    else
        # Duplicate options
        return 1
    fi
}


function _frija_extract_options()
{
    local optionList="${1}"
    local prefix="${2}"
    local result=""

    optionList="${optionList//,/$'\n'}"

    local type
    declare -i index
    index=0
    # Iterate through $optionList and determine kind of option, i.e.
    # if it has an argument and if so wheter it is an optional or
    # mandatory argument. Same notation as getopt uses is expected,
    # i.e. option suffix determine kind of option
    #
    # ::  Optional option argument
    #  :  Mandatory option argument
    #     No option argument (no suffix)
    while read -r option; do
        if [[ -n "${option}" ]]; then
            [[ "${option}" =~ ^([^:]+)(:*)$ ]]
            option="${BASH_REMATCH[1]}"
            type="${BASH_REMATCH[2]}"

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

            index+=1
        fi
    done <<< "${optionList}"
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
    _frija_update_subcommand_state

    # Initialize global array and associative array variables
    local optionList

    optionList=$(_frija_convert_shortopts "${_FRIJA_SHORTOPTS}")
    # shellcheck disable=SC2181
    [[ $? -eq 0 ]] || return 1

    _frija_extract_options "${optionList}" "-"
    # shellcheck disable=SC2181
    [[ $? -eq 0 ]] || return 1

    _frija_extract_options "${_FRIJA_LONGOPTS}" "--"
    # shellcheck disable=SC2181
    [[ $? -eq 0 ]] || return 1
}


function _frija_mandatory_option_completion()
{
    if [[ "${cur}" == "=" ]] || [[ "${prev}" == "=" ]] || \
           [[ -n "${prefix}" ]]; then
        local valueList
        valueList=$(_frija_internal_option_values "${option}")

        mapfile -t COMPREPLY < \
                <(compgen -P "${prefix}" -W "${valueList}" -- "${value}")

        if [[ "${COMPREPLY[*]}" == "${prefix}${value}" ]]; then
            # Single option has matched, move on to next by telling
            # complete to add a space.
            compopt +o nospace
        fi
    else
        # Add a '=' to current option so user can add an argument
        # value.
        mapfile -t COMPREPLY < <(compgen -W "${cur}=" -- "${cur}")
    fi
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
        valueList=$(_frija_internal_option_values "${option}")

        # Use mapfile to safely get output from compgen command into
        # COMPREPLY array variable.
        #
        # Note: The notation "<(...)" is called process substitution
        # and means that the output from the enclosed command appear
        # like a file. This is then redirected into the builtin
        # command mapfile using ordinary redirection.
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
        mapfile -t COMPREPLY < <(compgen -W "${cur} ${cur}=" -- "${value}")
    fi
}


# Main entry point for completion of Frija commands
function _frija()
{
    _frija_initialize

    local cur prev opts
    local index
    local type
    local option

    # Global variable COMPREPLY hold an array of completion results,
    # initialize it to an empty array
    COMPREPLY=()

    # $COMP_WORDS is an array of current command line items where for
    # instance any '=' are stored as separate words. $COMP_CWORD is
    # current index into this array.
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

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

        if [[ -n "${option}" ]]; then
            # If we have an option, try to look it up in our
            # associative array to get an index for it. This index
            # gives us information regarding whether it have a
            # mandatory argument, an optional argument, or no argument
            # at all.
            #
            # Note that this might not always succeed, since it might
            # be a partially completed option.
            index="${_FRIJA_OPT_INDEXES[$option]}"
        fi

        # Ensure that both the identified option is among the allowed
        # options AND that the index returned from the search is a
        # non-empty string.
        if [[ "${opts}" == *"${option}"* ]] && [[ -n "${index}" ]]; then
            type="${_FRIJA_OPT_TYPE[index]}"

            compopt -o nospace
            case "${type}" in
                # Case alternatives stored in variables

                "${_FRIJA_OPTIONAL_TYPE}")
                    # Optional type alternative
                    _frija_optional_option_completion \
                        "${cur}" "${prev}" "${prefix}" "${option}" "${value}"
                    return 0
                    ;;
                "${_FRIJA_MANDATORY_TYPE}")
                    # Mandatory type alternative
                    _frija_mandatory_option_completion \
                        "${cur}" "${prev}" "${prefix}" "${option}" "${value}"
                    return 0
                    ;;
                # Neither optional nor mandatory type
                *)
                    # Negating nospace, i.e. space is added after option
                    compopt +o nospace

                    mapfile -t COMPREPLY < <(compgen -W "${cur}" -- "${cur}")
                    return 0
                    ;;
            esac
        elif [[ "${prev}" == "=" ]]; then
            # Negating nospace, i.e. space is added after option
            compopt +o nospace

            mapfile -t COMPREPLY < <(compgen -W "${cur}" -- "${cur}")
            return 0
        fi
    fi

    if [[ "${variant}" == "${command}" ]]; then
        # Subcommand name has been completed, add space
        compopt +o nospace
    fi

    mapfile -t COMPREPLY < <(compgen -W "${opts}" -- "${cur}")

    if [[ "${#COMPREPLY[@]}" -eq 1 ]]; then
        _frija_update_subcommand_state "${COMPREPLY[*]}"
    elif [[ "${#COMPREPLY[@]}" -eq 0 ]] && \
             [[ "${option}" == "${_FRIJA_SUBCOMMAND_NAME}" ]]; then
        # Redo command completion since we have now identified that
        # last option is a subcommand name and we want to ensure there
        # is a space after the command name...
        mapfile -t COMPREPLY < <(compgen -W "${option}" -- "${option}")
    fi

    return 0
}

complete -o nospace -F _frija frija
