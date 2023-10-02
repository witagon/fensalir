#!/bin/bash

declare -A _FRIJA_SUBCOMMANDS

# List of available subcommands
_FRIJA_SUBCOMMAND_LIST=""

# Currently selected subcommand
_FRIJA_SUBCOMMAND_NAME=""


declare -a _FRIJA_SHORTOPT_ARRAY
declare -a _FRIJA_LONGOPT_ARRAY
declare -a _FRIJA_OPT_TYPE

declare -a _FRIJA_USED_OPTIONS
declare -A _FRIJA_OPT_INDEXES

#declare _FRIJA_CURRENT_ARGUMENT

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


## Return list of argument name placeholder values.; expected to be
## overridden by subcommand.
##
## Default implementation!
#function _frija_subcommand_argument_list()
#{
#    echo ""
#}
#
#
## $1 contains name of placeholder argument name, i.e. the one used in
## the help message (e.g. "FILE").; expected to be overridden by subcommand.
##
## Default implementation!
#function _frija_subcommand_argument_values()
#{
#    echo ""
#}


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

    {
        echo ">>> _frija_internal_option_values"
        echo "_FRIJA_SUBCOMMAND_NAME: ${_FRIJA_SUBCOMMAND_NAME}"
        echo "option: ${1}"
    } >> /tmp/foo.log

    if [[ -n "${_FRIJA_SUBCOMMAND_NAME}" ]]; then
        echo "Getting subcommand option values" >> /tmp/foo.log
        result=$(_frija_subcommand_option_values "${1}")
    else
        echo "Getting command option values" >> /tmp/foo.log
        result=$(_frija_command_option_values "${1}")
    fi

    echo "result: ${result}" >> /tmp/foo.log
    echo "<<< _frija_internal_option_values" >> /tmp/foo.log

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

    {
        echo "currentItems: '${currentItems[*]}'"
        echo "#currentItems: '${#currentItems[@]}'"
        echo "currentItems-indexes: '${!currentItems[*]}'"
        echo "** Resetting _FRIJA_SUBCOMMAND_NAME!!!!!"
    } >> /tmp/foo.log

    _FRIJA_SUBCOMMAND_NAME=""
    if [[ "${#currentItems[@]}" -eq 0 ]]; then
        echo "BEFORE for-loop" >> /tmp/foo.log
        echo "Resetting _FRIJA_CURRENT_ARGUMENT (${_FRIJA_CURRENT_ARGUMENT})" >> /tmp/foo.log

        _FRIJA_CURRENT_ARGUMENT=""

        # No need to iterate through an empty array...
        return
    fi

    for index in "${!currentItems[@]}"; do
        item="${currentItems[${index}]}"
        echo "index=${index}: item='${item}'" >> /tmp/foo.log
        # Extract just the option
        [[ "${item}" =~ ^(-[^-]|--[^=]+).*$ ]]
        option="${BASH_REMATCH[1]}"
        echo "option='${option}'" >> /tmp/foo.log

        if [[ "${item}" != "" ]] && [[ "${option}" == "" ]]; then
            # We have a candidate for a subcommand
            {
                echo "_FRIJA_SUBCOMMANDS[${item}]"
                echo "_FRIJA_SUBCOMMANDS[${item}]=${_FRIJA_SUBCOMMANDS[${item}]}"
            } >> /tmp/foo.log

            # Check if we have a match (whether $item is a registered
            # subcommand or not)
            subcommand="${_FRIJA_SUBCOMMANDS[${item}]}"
            if [[ -n "${subcommand}" ]]; then
                shortOpts="$(_frija_subcommand_shortoptions)"
                longOpts="$(_frija_subcommand_longoptions)"

                # Save current subcommand name
                _FRIJA_SUBCOMMAND_NAME="${item}"

                # No need for subcommand-list any more
                _FRIJA_SUBCOMMAND_LIST=""

                echo "_FRIJA_SUBCOMMAND_NAME=${_FRIJA_SUBCOMMAND_NAME}" >> /tmp/foo.log
                echo "Sourcing ${METADATATOOLS_HOME}/frija-${_FRIJA_SUBCOMMAND_NAME}" >> /tmp/foo.log
                # Source subcommand to bring its functions into the environment
                # shellcheck source=./.core_config.bash
                source "${METADATATOOLS_HOME}/frija-${_FRIJA_SUBCOMMAND_NAME}"


                # Exit from for-loop
                break
            fi
        fi
    done

    {
        item="${currentItems[-1]}"
        echo "_frija_update_subcommand_state()"
        echo "_FRIJA_SUBCOMMAND_LIST (${_FRIJA_SUBCOMMAND_LIST})"
        echo "_FRIJA_SUBCOMMAND_NAME (${_FRIJA_SUBCOMMAND_NAME})"
        echo "item (${item})"
        echo "_FRIJA_SUBCOMMANDS[${item}] (${_FRIJA_SUBCOMMANDS[${item}]})"
        echo "currentItems[@] (${currentItems[*]})"
        echo "currentItems[-1] (${currentItems[-1]})"
    } >> /tmp/foo.log

    # If a subcommand name has been found and the last option of
    # COMP_WORDS starts with "-" then there is no ongoing argument
    # comletion and _FRIJA_CURRENT_ARGUMENT should be reset
    if [[ -n "${_FRIJA_SUBCOMMAND_NAME}" ]]; then
        item="${currentItems[-1]}"
        if [[ "${item}" =~ ^[-].*$ ]] || \
               [[ -n "${_FRIJA_SUBCOMMANDS[${item}]}" ]]; then
            echo "Resetting _FRIJA_CURRENT_ARGUMENT (${_FRIJA_CURRENT_ARGUMENT})" >> /tmp/foo.log
            _FRIJA_CURRENT_ARGUMENT=""
        fi
    fi
}


function _frija_filter_options()
{
    echo "" >> /tmp/foo.log
    echo ">>> _frija_filter_options" >> /tmp/foo.log
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
    declare -a availableItems

    if [[ "${lastIndex}" -lt 1 ]]; then
        # "Everything" should be removed from $COMP_WORDS array.
        currentItems=()
    else
        # Slice a portion from $COMP_WORDS array so that both the
        # command name is removed AND a suitable part of the end is
        # also (possibly) removed depending on above cases.
        currentItems=("${COMP_WORDS[@]:1:${lastIndex}}")
    fi

    echo "currentItems: ${currentItems[*]}" >> /tmp/foo.log

    availableItems=("${!_FRIJA_OPT_INDEXES[@]}")
    echo "availableItems: ${availableItems[*]}" >> /tmp/foo.log

    # Clear array containing indexes of used options so we then can
    # fill it with those actually used. Once that is done we can
    # filter out those that are not used. :)
    _FRIJA_USED_OPTIONS=()

    local item=""
    local pos=""
    local filteredItems=""

    {
        echo "Filtering..."
        echo "Pass #1: "
        echo "indexes: ${!currentItems[*]}"
        echo "#indexes: ${#currentItems[*]}"
        echo "items: ${currentItems[*]}"
    } >> /tmp/foo.log

    declare -i index
    for index in "${!currentItems[@]}"; do
        item="${currentItems[${index}]}"
        # Extract just the option
        [[ "${item}" =~ ^(-[^-]|--[^=]+).*$ ]]
        item="${BASH_REMATCH[1]}"

        #echo "index=${index}: item='${item}'" >> /tmp/foo.log
        #echo "foo" >> /tmp/foo.log
        #echo "bar" >> /tmp/foo.log
        if [[ -n "${item}" ]]; then
            pos="${_FRIJA_OPT_INDEXES[${item}]}"

            #echo "index=${index}: item='${item}'  pos='${pos}'" >> /tmp/foo.log

            type="${_FRIJA_OPT_TYPE[pos]}"

            {
                echo "type is '${type}'"
                echo "item is '${item}'"
                echo "_FRIJA_USED_OPTIONS='${_FRIJA_USED_OPTIONS[*]}'"
                echo "filtered option is '${_FRIJA_USED_OPTIONS[${pos}]}'"
            } >> /tmp/foo.log

            #_FRIJA_USED_OPTIONS["${pos}"]=""
            if [[ -n "${pos}" ]]; then
                _FRIJA_USED_OPTIONS["${pos}"]="${pos}"
            else
                _FRIJA_USED_OPTIONS["${pos}"]=""
            fi

            #echo "${item}:${pos} (_FRIJA_USED_OPTIONS[${pos}]=${_FRIJA_USED_OPTIONS[${pos}]})" >> /tmp/foo.log
        else
            echo "Found scrap: '${currentItems[${index}]}'" >> /tmp/foo.log
        fi
    done

    {
        echo "_FRIJA_USED_OPTIONS: ${_FRIJA_USED_OPTIONS[*]}"
        echo "_FRIJA_SHORTOPT_ARRAY: ${!_FRIJA_SHORTOPT_ARRAY[*]}"

        echo "Pass #2: "
    } >> /tmp/foo.log

    for index in "${!_FRIJA_SHORTOPT_ARRAY[@]}"; do
        pos="${_FRIJA_USED_OPTIONS[${index}]}"
        #echo "index=${index}:  pos=${pos}" >> /tmp/foo.log
        if [[ "${pos}" == "" ]]; then
            filteredItems+=" ${_FRIJA_SHORTOPT_ARRAY[${index}]}"
            filteredItems+=" ${_FRIJA_LONGOPT_ARRAY[${index}]}"
            #echo "${filteredItems}" >> /tmp/foo.log
        fi
    done
    {
        echo "${filteredItems}"
        echo "Done..."
        echo "<<< _frija_filter_options"
        echo ""
    } >> /tmp/foo.log

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

    echo "_frija_extract_options: optionList=${optionList}" >> /tmp/foo.log
    echo "_frija_extract_options: prefix=${prefix}" >> /tmp/foo.log

    # echo "optionList: ${optionList}" >&2
    optionList="${optionList//,/$'\n'}"

    local type
    declare -i index
    index=0
    while read -r option; do
        if [[ -n "${option}" ]]; then
            [[ "${option}" =~ ^([^:]+)(:*)$ ]]
            option="${BASH_REMATCH[1]}"
            type="${BASH_REMATCH[2]}"

            case "${type}" in
                "::")
                    # echo "${prefix}${option} (optional arg)" >> /tmp/foo.log
                    type="${_FRIJA_OPTIONAL_TYPE}"
                    ;;
                ":")
                    # echo "${prefix}${option} (mandatory arg)" >> /tmp/foo.log
                    type="${_FRIJA_MANDATORY_TYPE}"
                    ;;
                *)
                    # echo "${prefix}${option} (no arg)" >> /tmp/foo.log
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

    # echo "short options: ${options}" >&2

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

    # echo "result: ${result}" >&2

    echo "${result}"
}


function _frija_initialize()
{
    # Assume we should use base commands options
    local shortOpts
    local longOpts
    shortOpts="$(_frija_shortoptions)"
    longOpts="$(_frija_longoptions)"

    _frija_update_subcommands
    _frija_update_subcommand_state

    # Reset global array variables
    _FRIJA_SHORTOPT_ARRAY=()
    _FRIJA_LONGOPT_ARRAY=()
    _FRIJA_OPT_TYPE=()
    _FRIJA_USED_OPTIONS=()

    # Reset global associative array variable
    _FRIJA_OPT_INDEXES=()

    # Initialize global array and associative array variables
    local optionList

    optionList=$(_frija_convert_shortopts "${shortOpts}")
    # shellcheck disable=SC2181
    [[ $? -eq 0 ]] || return 1

    _frija_extract_options "${optionList}" "-"
    # shellcheck disable=SC2181
    [[ $? -eq 0 ]] || return 1

    _frija_extract_options "${longOpts}" "--"
    # shellcheck disable=SC2181
    [[ $? -eq 0 ]] || return 1
}


function _frija_print_state()
{
    echo "${_FRIJA_OPT_TYPE[@]}"
    echo "${!_FRIJA_OPT_INDEXES[@]}"
    echo "${_FRIJA_OPT_INDEXES[@]}"
}



_frija()
{
    {
        echo ""
        echo "---------------------------------------"
        echo ">>> _frija"
    } >> /tmp/foo.log
    _frija_initialize

    local cur prev opts
    local index
    local type
    local option

    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts=$(_frija_filter_options)

    {
        echo "opts='${opts}'"
        echo "_FRIJA_SUBCOMMAND_NAME='${_FRIJA_SUBCOMMAND_NAME}'"
        echo ""
    } >> /tmp/foo.log

    if [[ -n "${_FRIJA_SUBCOMMAND_NAME}" ]]; then
        echo "AAAAAAAAAA" >> /tmp/foo.log
        # We are in a subcommand
    else
        echo "DDDDDDDDDD" >> /tmp/foo.log
        # Append subcommand names to valid completions
        opts+=" ${_FRIJA_SUBCOMMAND_LIST}"
    fi

    {
        echo ""
        echo "####### START #######"
        echo "opts: ${opts}"

        echo "COMP_LINE: ${COMP_LINE}"
        echo "COMP_CWORD: ${COMP_CWORD}"
        echo "COMP_WORDS[${COMP_CWORD}]: ${COMP_WORDS[COMP_CWORD]}"
        echo "COMP_WORDS[@]: ${COMP_WORDS[*]}"
        # echo "COMP_POINT: ${COMP_POINT}"
        # echo "COMP_TYPE: ${COMP_TYPE}"
        # echo "COMP_KEY: ${COMP_KEY}"
        # echo "COMP_WORDBREAKS: ${COMP_WORDBREAKS}"
        echo "cur: '${cur}'"
        echo "prev: '${prev}'"
        # echo "\$1 (cmd name): '${1}'"
        # echo "\$2 (comp.wrd): '${2}'"
        # echo "\$3 (prec.wrd): '${3}'"

        echo "#######"
    }  >> /tmp/foo.log

    local short="s"
    local long="l"
    local command="c"
    local argument="a"

    local value=""
    local variant=""
    local prefix=""

    if [[ -n "${cur}" ]]; then
        if [[ "${prev}" == "=" ]] && [[ -n "${cur}" ]]; then
            option="${COMP_WORDS[COMP_CWORD-2]}"
        elif [[ "${cur}" == "=" ]]; then
            option="${prev}"
        else
            option="${cur}"
        fi

        echo "option: '${option}'" >> /tmp/foo.log

        # Detect if it is a short, long, or no option
        if [[ "${option}" =~ ^(-[^-])(.*)$ ]]; then
            option="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            variant="${short}"
            prefix="${option}"

            {
                echo "Short option detected!"
                echo "match: '${BASH_REMATCH[*]}'"
                echo "option: '${option}'"
                echo "value: '${value}'"
                echo "variant: '${variant}'"
                echo "prefix: '${prefix}'"
            } >> /tmp/foo.log

        elif [[ "${option}" =~ ^--.*$ ]]; then
            if [[ "${prev}" == "=" ]]; then
                value="${cur}"
            fi
            variant="${long}"
            {
                echo "Long option detected!"
                echo "option: '${option}'"
                echo "value: '${value}'"
                echo "variant: '${variant}'"
                echo "prefix: '${prefix}'"
            } >> /tmp/foo.log

        elif [[ "${option}" =~ ^[[:upper:]]+$ ]]; then
            variant="${argument}"
            {
                echo "Argument detected!"
                echo "option: '${option}'"
                echo "value: '${value}'"
                echo "variant: '${variant}'"
                echo "prefix: '${prefix}'"
            } >> /tmp/foo.log
        else
            variant="${command}"
            {
                echo "Command detected!"
                echo "option: '${option}'"
                echo "value: '${value}'"
                echo "variant: '${variant}'"
                echo "prefix: '${prefix}'"
            } >> /tmp/foo.log
        fi

        echo "_FRIJA_OPT_INDEXES[${option}]=${_FRIJA_OPT_INDEXES[${option}]}" >> /tmp/foo.log
        index="${_FRIJA_OPT_INDEXES[${option}]}"
        echo "index=${index}" >> /tmp/foo.log
        echo "opts='${opts}'" >> /tmp/foo.log
        # Ensure that both the identified option is among the allowed
        # options AND that the index returned from the search is a
        # non-empty string.
        if [[ "${opts}" == *"${option}"* ]] && [[ -n "${index}" ]]; then
            echo "${option} have index ${index}" >> /tmp/foo.log
            type="${_FRIJA_OPT_TYPE[index]}"
            echo "type is '${type}'" >> /tmp/foo.log

            compopt -o nospace
            case "${type}" in
                "${_FRIJA_OPTIONAL_TYPE}")
                    echo "type is OPTIONAL" >> /tmp/foo.log

                    if [[ "${cur}" == "=" ]] || [[ "${prev}" == "=" ]] \
                           || [[ -n "${prefix}" ]]; then
                        local valueList
                        valueList=$(_frija_internal_option_values "${option}")

                        # Use mapfile to safely get output from
                        # compgen command into COMPREPLY array
                        # variable.
                        #
                        # Note: The notation "<(...)" is called
                        # process substitution and means that the
                        # output from the enclosed command appear like
                        # a file. This is then redirected into the
                        # builtin command mapfile using ordinary
                        # redirection.
                        mapfile -t COMPREPLY < <(compgen -P "${prefix}" \
                                                         -W "${valueList}" \
                                                         -- "${value}")
                        echo "1: COMPREPLY='${COMPREPLY[*]}'" >> /tmp/foo.log

                        if [[ "${COMPREPLY[*]}" == "${prefix}${value}" ]]; then
                            # Single option has matched, move on to
                            # next by telling complete to add a space.
                            compopt +o nospace
                            echo "1: Negating nospace" >> /tmp/foo.log
                        fi
                    else
                        # Add a '=' to current option so user can add
                        # an argument value.
                        mapfile -t COMPREPLY < <(compgen -W "${cur} ${cur}=" \
                                                         -- "${value}")
                        echo "2: COMPREPLY='${COMPREPLY[*]}'" >> /tmp/foo.log
                    fi
                    return 0
                    ;;
                "${_FRIJA_MANDATORY_TYPE}")
                    echo "type is MANDATORY" >> /tmp/foo.log

                    if [[ "${cur}" == "=" ]] || [[ "${prev}" == "=" ]] || \
                           [[ -n "${prefix}" ]]; then
                        local valueList
                        valueList=$(_frija_internal_option_values "${option}")

                        mapfile -t COMPREPLY < <(compgen -P "${prefix}" \
                                                         -W "${valueList}" \
                                                         -- "${value}")
                        echo "1: COMPREPLY='${COMPREPLY[*]}'" >> /tmp/foo.log

                        if [[ "${COMPREPLY[*]}" == "${prefix}${value}" ]]; then
                            # Single option has matched, move on to
                            # next by telling complete to add a space.
                            compopt +o nospace
                            echo "1: Negating nospace" >> /tmp/foo.log
                        fi
                    else
                        # Add a '=' to current option so user can add
                        # an argument value.
                        mapfile -t COMPREPLY < <(compgen -W "${cur}=" \
                                                         -- "${cur}")
                        echo "2: COMPREPLY='${COMPREPLY[*]}'" >> /tmp/foo.log
                    fi
                    return 0
                    ;;
                *)
                    compopt +o nospace

                    {
                        echo "type is neither OPTIONAL nor MANDATORY"
                        echo "Negating nospace"
                    } >> /tmp/foo.log

                    mapfile -t COMPREPLY < <(compgen -W "${cur}" -- "${cur}")
                    echo "COMPREPLY='${COMPREPLY[*]}'" >> /tmp/foo.log
                    return 0
                    ;;
            esac
        elif [[ "${prev}" == "=" ]]; then
            echo "cur=${cur}  prev=${prev}  option=${option}" >> /tmp/foo.log

            echo "Negating nospace" >> /tmp/foo.log
            compopt +o nospace

            mapfile -t COMPREPLY < <(compgen -W "${cur}" -- "${cur}")
            echo "COMPREPLY='${COMPREPLY[*]}'" >> /tmp/foo.log
            return 0
        fi
    fi

    {
        echo "====== END ======="
        echo "variant=${variant}  argument=${argument}" >> /tmp/foo.log
    } >> /tmp/foo.log

    if [[ "${variant}" == "${command}" ]]; then
        echo "Negating nospace" >> /tmp/foo.log
        compopt +o nospace
    fi

    mapfile -t COMPREPLY < <(compgen -W "${opts}" -- "${cur}")

    if [[ "${#COMPREPLY[@]}" -eq 1 ]]; then
        echo "Updating subcommand state" >> /tmp/foo.log
        _frija_update_subcommand_state "${COMPREPLY[*]}"
    elif [[ "${#COMPREPLY[@]}" -eq 0 ]] && \
             [[ "${option}" == "${_FRIJA_SUBCOMMAND_NAME}" ]]; then
        # Redo command completion since we have now identified that
        # last option is a subcommand name and we want to ensure there
        # is a space after that name the command name...
        mapfile -t COMPREPLY < <(compgen -W "${option}" -- "${option}")
    fi

    {
        echo "opts='${opts}'"
        echo "cur='${cur}'"
        echo "_FRIJA_SUBCOMMAND_LIST='${_FRIJA_SUBCOMMAND_LIST[*]}'"
        echo "_FRIJA_SUBCOMMAND_NAME='${_FRIJA_SUBCOMMAND_NAME}'"
        echo "_FRIJA_CURRENT_ARGUMENT='${_FRIJA_CURRENT_ARGUMENT}'"
        echo "COMPREPLY='${COMPREPLY[*]}'"
        echo "=================="
        echo ""
    } >> /tmp/foo.log

    return 0
}

complete -o nospace -F _frija frija

echo "" > /tmp/foo.log


#_frija_print_state
