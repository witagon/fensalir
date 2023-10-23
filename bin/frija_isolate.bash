# Wrapper script used for running a build command in an isolated
# environment. This script is intended to be called using the env
# command that start a bash process that reads from this script. That
# is
#
# env --ignore-environment bash --noprofile --norc /path/to/this/script
#
# This script then requires FOUR parameters, see below for a short
# description of each of them.

################################################################################
# FIRST argument is path to the root of the locale repo to read from


################################################################################
# SECOND argument is the version within the repo to read from; this is
# either a Git version tag OR the keyword 'floating'. The latter means
# whatever is currently checkout in the repo.


################################################################################
# THIRD argument is a comma-separated list of .seci-files to read from
# (these are assumed to be locted in the seci-folder found in the root
# of the locale repo). This means that listed .seci-filenames may not
# contain any commas, which ought not to be any big problem. ;)
#
# Note that this means that the content of listed .seci files is
# additive and are added together in the given order.
#
# A .seci-file in turn uses a line- and column-based format where each
# column is separated by whitespace. Note that empty lines are allowed
# and lines starting with '#' are considererd to be comments. The
# first column contain an instruction where the set of allowed
# instructions are
#
#
# conflict <symbol>
#
# Checks if the given <symbol> exist or not, if it does exist then an
# error is raied. If it does not exist then it is set to the name of
# the .seci-file. This works more or less as some kind of "include
# guard" in C/C++ header files (sanity check that the same kind of
# file is not read twice)
#
#
# local <name> <value>
#
# Defines given name as a local variable and assigns it the given
# value, that is the variable DOES NOT get exported into the
# environment of sub-processes. Can be useful if the same value is
# repeated several times. A local variable value is expanded using
# plain Bash variable expansion notation; to insert the value of name
# use ${name}. Note that no other types of expansions are allowd and
# result in an error.
#
# Note that if the named variable already exist then an error is
# raised.
#
#
# set <name> <value>
#
# Defines given name as an exported variable and assigns it the given
# value, that is the variable DOES get exported into the environment
# of sub-processes. An exported variable value is expanded using plain
# Bash variable expansion notation; to insert the value of name use
# ${name}. Note that no other types of expansions are allowd and
# result in an error.
#
# Note that if the named variable already exist then an error is
# raised.
#
#
# prepend <name> <value>
#
# If NO variable exist with the given name then an exported variable
# is created and assigned the given value. If a variable with the
# given name DO exist, then the given value is PREPENDED (added at the
# front) to the existing value with a ':' separator inserted
# in-between (Unix/Linux PATH separator). The resulting value is
# exported into the environment of sub-processes.
#
# A local or exported variable value can be expanded within the value
# part using plain Bash variable expansion notation; to insert the
# value of name use ${name}. Note that no other types of expansions
# are allowd and result in an error.
#
#
# append <name> <value>
#
# If NO variable exist with the given name then an exported variable
# is created and assigned the given value. If a variable with the
# given name DO exist, then the given value is APPENDED (added at the
# end) to the existing value with a ':' separator inserted in-between
# (Unix/Linux PATH separator). The resulting value is exported into
# the environment of sub-processes.
#
# A local or exported variable value can be expanded within the value
# part using plain Bash variable expansion notation; to insert the
# value of name use ${name}. Note that no other types of expansions
# are allowd and result in an error.
#
#
# Example .seci file
#
# conflict  gcc
# local     GCC_HOME          "/sw/gcc/4.9.4-shared/bin"
# prepend   PATH              "${GCC_HOME}"
# prepend   LD_LIBRARY_PATH   "${GCC_HOME}/lib64"
# set       CC                "gcc"
# set       CXX               "g++"


################################################################################
# FOURTH argument is 'wordyness'; if exactly the string "y" then extra
# meta-information about constructed environment etc. is printed to
# the terminal.


################################################################################
# FIFTH argument (and rest of command line) is assumed to be the
# command to execute.


################################################################################

function error_handler()
{
    declare -i error=$?

    echo "${BASH_LINENO[0]}:${FUNCNAME[1]}: Resulted in exit code ${error}" 1>&2
    echo "Script ${0} aborted." 1>&2
}



################################################################################
# START OF SCRIPT
################################################################################

# Install error handler that prints an error message when there is an error
trap error_handler ERR

# Trigger ERR trap for commands returning an exit code greater than 0.
# Exit code from commands preceded with '!' are ignored.
set -o errexit

_FRIJA_PROGRAM_PATH=$(readlink -e "${0}")


# Path to locale repo
localePath="${1}"

# Check if locale path is empty
if [[ -z "${localePath}" ]]; then
    message="${_FRIJA_PROGRAM_PATH}: ERROR: Given locale path "
    message+="(expected 1st argument) is an empty string.\\n"
    message+="Given arguments are: '$*'"

    # Print error message to stderr and exit with an error code
    echo -e "${message}" 1>&2
    exit 1
fi


# Version to select within locale repo; an empty string is an error
localeVersion="${2}"

# Check if given version is empty
if [[ -z "${localeVersion}" ]]; then
    message="${_FRIJA_PROGRAM_PATH}: ERROR: Given version "
    message+="(expected 2nd argument) is an empty string.\\n"
    message+="Given arguments are: '$*'"

    # Print error message to stderr and exit with an error code
    echo -e "${message}" 1>&2
    exit 1
fi


# List of comma-separated .seci-files to read from; may be an empty string
secilist="${3}"


# 'Wordiness' to use
wordy="${4}"


# Command to execute; any additional arguments are sent as arguments
# to this command
cmd="${5}"

# Check if given command to execute is empty
if [[ -z "${cmd}" ]]; then
    message="${_FRIJA_PROGRAM_PATH}: ERROR: Given command to execute "
    message+="(expected 4th argument) is an empty string.\\n"
    message+="Given arguments are: '$*'"

    # Print error message to stderr and exit with an error code
    echo -e "${message}" 1>&2
    exit 1
fi

# Since all arguments after position #5 are treated as options for the
# command to execute, shift options four steps so $5 becomes $1, $6
# becomes $2, and so on.
shift 5


if [[ ! -v _FRIJA_HOME_FOLDER ]]; then
    # On Linux glibc is "helpful" and sets PATH to
    # /usr/local/bin:/usr/bin if it is empty...
    #
    # Thus if this script is running in a clean environment, that is
    # $_FRIJA_HOME_FOLDER is not set, then $PATH must be forced to be
    # empty to mitigate glibc behavior.
    export PATH=""
fi

if [[ "${wordy}" == "y" ]]; then
    echo "" 1>&2
    echo "Initial environment given to us" 1>&2
    echo "===============================" 1>&2
    /usr/bin/env 1>&2
    echo "===============================" 1>&2
    echo "" 1>&2
fi

################################################################################
# BELOW THIS POINT ONLY BASH BUILTINS MAY BE USED EXPLICITLY WITHIN SCRIPT
################################################################################


function print_debug_enter()
{
    if [[ -z "${DEBUG}" ]]; then
        return 0
    fi

    echo "==>  ${FUNCNAME[2]}():${BASH_LINENO[1]} => ${FUNCNAME[1]}(): $*" 1>&2
}


function print_debug_exit()
{
    if [[ -z "${DEBUG}" ]]; then
        return 0
    fi

    echo "<==  ${FUNCNAME[2]}():${BASH_LINENO[1]} <= ${FUNCNAME[1]}()" 1>&2
}

function sanity_check_string()
{
    print_debug_enter "$@"
    local value="${1}"
    local regex="^[^$\`]*(([$][{][-a-zA-Z_0-9]+[}])*[^$\`]*)*$"
    local row="${3}"
    local filename="${4}"

    if [[ "${value}" =~ $regex ]]; then
        # $value is safe to evaluate; that is it contain zero or more
        # plain variable references using "${foobar}" notation, and
        # not trickery like $(foo) or `foo` that causes Bash to
        # execute something.
        :
    else
        message="${_FRIJA_PROGRAM_PATH}: ERROR: Variable "
        message+="'${variable}' on row ${row} in '${secifile}' may not be "
        message+="assigned value ('${value}') since it has too complex "
        message+="variable references; only plain variable references "
        message+="using \${} notation is allowed, aborting."

        echo "${message}" 1>&2
        exit 2
    fi
    print_debug_exit
}


function process_conflict()
{
    print_debug_enter "$@"
    local variable="${1}"
    local value="${2}"
    local row="${3}"
    local filename="${4}"

    if [[ ! -v "${variable}" ]]; then
        if [[ "${wordy}" == "y" ]]; then
            echo "Creating variable '${variable}' with value '${value}'" 1>&2
        fi
        # Create a global variable for conflict detection
        declare -g "${variable}"="${value}"
        # echo "${variable}=${!variable}"
    else
        local message="${_FRIJA_PROGRAM_PATH}: ERROR: Conflict "
        message+="between SECI definitions found; "
        message+="'${variable}' on row ${row} in '${secifile}' has "
        message+="already been defined in '${value}', aborting."

        echo "${message}" 1>&2
        exit 2
    fi

    print_debug_exit
}


function process_local()
{
    print_debug_enter "$@"
    local variable="${1}"
    local value="${2}"
    local row="${3}"
    local filename="${4}"

    local message=""
    if [[ -z "${!variable}" ]]; then
        sanity_check_string "${value}" "${row}" "${filename}"

        # Assign $value to the variable named in $variable and make it
        # global, but DO NOT make it available to sub-processes
        #
        # shellcheck disable=SC2086
        export -n "${variable}"="$(eval echo ${value})"
    else
        local message="${_FRIJA_PROGRAM_PATH}: ERROR: Variable "
        message+="'${variable}' on row ${row} in '${secifile}' may not be "
        message+="assigned another value ('${value}') since it has already "
        message+="been assigned value '${!variable}', aborting."

        echo "${message}" 1>&2
        exit 2
    fi

    print_debug_exit
}


function process_set()
{
    print_debug_enter "$@"
    local variable="${1}"
    local value="${2}"
    local row="${3}"
    local filename="${4}"

    local message=""
    if [[ -z "${!variable}" ]]; then
        sanity_check_string "${value}" "${row}" "${filename}"

        # Assign $value to the variable named in $variable and
        # make it available to sub-processes
        #
        # At the same time make indirectly referenced variable
        # available to sub-processes.
        #
        # shellcheck disable=SC2086
        export "${variable}"="$(eval echo ${value})"
    else
        local message="${_FRIJA_PROGRAM_PATH}: ERROR: Variable "
        message+="'${variable}' on row ${row} in '${secifile}' may not be "
        message+="assigned another value ('${value}') since it has already "
        message+="been assigned value '${!variable}', aborting."

        echo "${message}" 1>&2
        exit 2
    fi

    print_debug_exit
}


function process_append()
{
    print_debug_enter "$@"
    local variable="${1}"
    local value="${2}"
    local row="${3}"
    local filename="${4}"

    sanity_check_string "${value}" "${row}" "${filename}"

    if [[ -z "${!variable}" ]]; then
        # Assign $value to the variable named in $variable
        #
        # At the same time make indirectly referenced variable
        # available to sub-processes.
        #
        # shellcheck disable=SC2086
        export "${variable}"="$(eval echo ${value})"
    else
        # Append $value; this is done by an indirect reference to
        # the variable name stored in $variable. That is, if
        # $foo="123" and $bar="foo", then "${!bar}" result in
        # "123" and not "foo" due to the '!' in front of the
        # variable name.
        #
        # At the same time make indirectly referenced variable
        # available to sub-processes.
        #
        # shellcheck disable=SC2086,SC2140
        export "${variable}"="${!variable}:$(eval echo ${value})"
    fi

    print_debug_exit
}


function process_prepend()
{
    print_debug_enter "$@"
    local variable="${1}"
    local value="${2}"
    local row="${3}"
    local filename="${4}"

    sanity_check_string "${value}" "${row}" "${filename}"

    if [[ -z "${!variable}" ]]; then
        #echo "%%%: ${variable} has no value"

        # Assign $value to the variable named in $variable
        #
        # At the same time make indirectly referenced variable
        # available to sub-processes.
        #
        # shellcheck disable=SC2086
        export "${variable}"="$(eval echo ${value})"
    else
        #echo "%%%: ${variable} has value '${!variable}'"

        # Prepend $value; this is done by an indirect reference to
        # the variable name stored in $variable. That is, if
        # $foo="123" and $bar="foo", then "${!bar}" result in
        # "123" and not "foo" due to the '!' in front of the
        # variable name.
        #
        # At the same time make indirectly referenced variable
        # available to sub-processes.
        #
        # shellcheck disable=SC2086,SC2140
        export "${variable}"="$(eval echo ${value}):${!variable}"
    fi

    print_debug_exit
}


function process_instruction()
{
    print_debug_enter "$@"
    local filename="${1}"
    local row="${2}"
    local instruction="${3}"
    local variable="${4}"
    local value="${5}"


    if [[ -z "${instruction}" ]] || \
           [[ "${instruction}" == "#"* ]];
    then
        # Skip empty or commented lines
        return
    fi

    if [[ -z "${variable}" ]]; then
        local message="${_FRIJA_PROGRAM_PATH}: ERROR: Empty "
        message+="variable name found in "
        message+="'${secifile}' on row ${row}, aborting."

        # Print error message to stderr and exit with an error code
        echo "${message}" 1>&2
        exit 2
    fi

    case "${instruction}" in
        "conflict")
            # Conflict variable is not assigned via value from
            # .seci file, instead it is assigned the name of the
            # file that defines it. Thus we must check if $value
            # is non-empty and abort with an error message if that
            # is the case.
            if [[ -n "${value}" ]]; then
                local message="${_FRIJA_PROGRAM_PATH}: ERROR: Conflict "
                message+="declaration on row ${row} in '${filename}' "
                message+="may only define a symbol but must "
                message+="not give any additional parameters such as "
                message+="'${value}', aborting."

                # Print error message to stderr and exit with an error code
                echo "${message}" 1>&2
                exit 2
            fi

            process_conflict "${variable}" "${filename}" "${row}" "${filename}"
            ;;
        "local")
            if [[ "${wordy}" == "y" ]]; then
                echo "Local variable '${variable}' with value '${value}'" 1>&2
            fi
            process_local "${variable}" "${value}" "${row}" "${filename}"
            ;;
        "set")
            if [[ "${wordy}" == "y" ]]; then
                echo "Export variable '${variable}' with value '${value}'" 1>&2
            fi
            process_set "${variable}" "${value}" "${row}" "${filename}"
            ;;
        "append")
            if [[ "${wordy}" == "y" ]]; then
                echo "Append '${value}' to variable '${variable}'" 1>&2
            fi
            process_append "${variable}" "${value}" "${row}" "${filename}"
            if [[ "${wordy}" == "y" ]]; then
                echo "  Result is '${!variable}'" 1>&2
            fi
            ;;
        "prepend")
            if [[ "${wordy}" == "y" ]]; then
                echo "Prepend '${value}' to variable '${variable}'" 1>&2
            fi
            process_prepend "${variable}" "${value}" "${row}" "${filename}"
            if [[ "${wordy}" == "y" ]]; then
                echo "  Result is '${!variable}'" 1>&2
            fi
            ;;
        *)
            local message="${_FRIJA_PROGRAM_PATH}: ERROR: Unknown "
            message+="instruction '${instruction}' found on row ${row} "
            message+="in '${filename}', aborting."

            # Print error message to stderr and exit with an error code
            echo "${message}" 1>&2
            exit 2
            ;;
    esac

    print_debug_exit
}


# Iterate over $secilist containing files with environment variable
# definitions; note that all definitions are assumed to be "additive"
# where multiple values are separated by ':'. That is, if the same
# variable name occurr multiple times (either wihin a single .seci
# file or across multiple files) then each new value found is
# prepended to any existing value and added to the current
# environment. All read values are also exported so they are copied
# into the environment of the executed command.

# Iterate over the input list which is assumed to be separated by ','.
# This is done by first splitting the string on ',' (replacing each
# ',' with a ' ') and then iterate over the result using a simple Bash
# for-loop

if [[ "${wordy}" == "y" ]]; then
    echo "Using locale '${localePath}'" 1>&2
fi

secifile=""
declare -i row=0
if [[ "${localeVersion}" == "floating" ]]; then
    for seci in ${secilist//,/ }; do
        if [[ "${wordy}" == "y" ]]; then
            echo "------------" 1>&2
            echo "Reading from '${seci}'" 1>&2
        fi
        secifile="${localePath}/SECI/${seci}"

        # Create an alias to avoid shellcheck warning SC2094 as the
        # situation it warns about is not applicable and it seems
        # impossible to disable the check for the row redirecting
        # $secifile into the while loop...
        filename="${secifile}"

        if [[ -f "${filename}" ]]; then
            while read -r instruction variable value rest; do
                # Strip any carriage returns from the read values
                instruction=${instruction//$'\r'}
                variable=${variable//$'\r'}
                value=${value//$'\r'}

                # Remember which row we are on; needed in error
                # printouts
                row=$(( row+1 ))

                #echo "BEFORE: filename='${filename}'" 1>&2
                #filename="${filename//+/-}"
                #echo " AFTER: filename='${filename}'" 1>&2
                #process_instruction "${filename}" \
                process_instruction "${seci}" \
                                    "${row}" \
                                    "${instruction}" \
                                    "${variable}" \
                                    "${value}"
            done < "${secifile}"
        else
            message="${_FRIJA_PROGRAM_PATH}: ERROR: "
            message+="Requested SECI file '${secifile}' "
            message+="(referenced by the input file) "
            message+="could not be found, aborting."

            # Print error message to stderr and exit with an error code
            echo "${message}" 1>&2
            exit 2
        fi
    done
else
    # Read localeVersion from Git-repo
    # Check if given tag exist in locale repo
    if ${GIT} -C "${localePath}" show-ref --tags "${localeVersion}" --quiet
    then
        # Read from given localeVersion in Git repo
        for secifile in ${secilist//,/ }; do
            if [[ "${wordy}" == "y" ]]; then
                echo "Reading from '${seci}'" 1>&2
                echo "------------" 1>&2
            fi
            # Build Git version specifier
            secifile="${localeVersion}:${BUILD_CONF}/${secifile}"

            # Check if requested .seci-file exist for this version in Git
            if ${GIT} -C "${localePath}" cat-file -e "${secifile}"
            then
                while read -r instruction variable value; do
                    # Strip any carriage returns from the read values
                    instruction=${instruction//$'\r'}
                    variable=${variable//$'\r'}
                    value=${value//$'\r'}

                    # Remember which row we are on; needed in error
                    # printouts
                    row=$(( row+1 ))

                    process_instruction "${filename}" \
                                        "${row}" \
                                        "${instruction}" \
                                        "${variable}" \
                                        "${value}"

                    # Use Process Substitution ('<(command)') to
                    # get output from a command into a while loop
                    # without creating a subshell executing the
                    # while loop
                done < <(${GIT} -C "${localePath}" cat-file "${secifile}")
            else
                message="${_FRIJA_PROGRAM_PATH}: ERROR: "
                message+="Requested SECI file '${secifile}' "
                message+="in locale '${localePath}' and Git tag "
                message+="${localeVersion} (referenced by the input file) "
                message+="could not be found, aborting."

                # Print error message to stderr and exit with an error code
                echo "${message}" 1>&2
                exit 2
            fi
        done
    else
        message="${_FRIJA_PROGRAM_PATH}: ERROR: "
        message+="Input file refers to tag '${localeVersion}' in "
        message+="locale '${localePath}', alas this tag "
        message+="does not exist, aborting."

        # Print error message to stderr and exit with an error code
        echo "${message}" 1>&2
        exit 2
    fi
fi

if [[ "${wordy}" == "y" ]]; then
    echo "" 1>&2
    echo "Created environment" 1>&2
    echo "===================" 1>&2
    /usr/bin/env 1>&2
    echo "=====================" 1>&2
    echo "" 1>&2

    type "${cmd}" 1>&2
    echo "Command to execute: exec '${cmd}' '$*'" 1>&2
    echo "Calling exec..." 1>&2
    echo "" 1>&2
fi

# Call the command with its options
exec "${cmd}" "$@"
