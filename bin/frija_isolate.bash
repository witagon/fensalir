# Wrapper script used for running a build command in an isolated
# environment. This script is intended to be called using the env
# command that start a bash process that reads from this script. That
# is
#
# env --ignore-environment bash --noprofile --norc /path/to/this/script
#
#
# This script requires TWO arguments
#
# FIRST argument is 'wordyness'; if exactly the string "y" then extra
# meta-information about environment and command to execute is printed
# to the terminal.
#
# SECOND argument (and rest of command line) is assumed to be the
# command to execute.


################################################################################

function error_handler()
{
    declare -i error=$?

    echo "${BASH_LINENO[0]}:${FUNCNAME[1]}: Resulted in exit code ${error}" 1>&2
    echo "Script ${0} aborted." 1>&2
}

# Install error handler that prints an error message when there is an
# error
trap error_handler ERR

# Trigger ERR trap for commands returning an exit code greater than 0.
# Exit code from commands preceded with '!' are ignored.
set -o errexit


################################################################################
# BELOW THIS POINT ONLY BASH BUILTINS MAY BE USED EXPLICITLY WITHIN SCRIPT
################################################################################

################################################################################
#  NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
################################################################################
#
# Note that this script avoids using variables and functions unless
# necessary to avoid tainting the environment.
#
################################################################################
#  NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
################################################################################


# Check if given command to execute is empty; $2 is the command to
# execute
if [[ -z "${2}" ]]; then
    message="Given command to execute "
    message+="(expected 2nd argument) is an empty string.\\n"
    message+="Given arguments are: '$*'"

    # Print error message to stderr and exit with an error code
    echo "$(readlink -e "${0}"): Error: ${message}" 1>&2
    exit 1
fi

if [[ "${1}" == "y" ]]; then
    echo "" 1>&2
    echo "INITIAL environment given to us" 1>&2
    echo "===============================" 1>&2
    /usr/bin/env 1>&2
    echo "===============================" 1>&2
    echo "" 1>&2
fi

if [[ ! -v _FRIJA_HOME_FOLDER ]]; then
    # On Linux glibc is "helpful" and sets PATH to
    # /usr/local/bin:/usr/bin if it is empty...
    #
    # Thus if this script is running in a clean environment, that is
    # $_FRIJA_HOME_FOLDER is not set, then $PATH must be forced to be
    # empty to mitigate glibc behavior.
    export PATH=""

    # The environment passed on to us might contain variables starting
    # with the prefix "FRIJA_", for instance "FRIJA_PATH". This prefix
    # trick enables us to reset PATH as we did above, what is left to
    # do is to create new copies of these variables with "FRIJA_"
    # prefix and export them without that prefix and at the same time
    # the prefixed variables should be removed from the environment.
    #
    # The "${!FOO@}" syntax below expands to all names matching given
    # prefix as words separated by spaces, in this case all variables
    # whos name starts with 'FOO'.
    #
    # The expression
    #
    #    export "${item#FRIJA_}"="${!item}"
    #
    # Consists of "${item#FRIJA_}" that removes the prefix 'FRIJA_'
    # from the expanded value of $item and "${!item}" that is indirect
    # value expansion. The latter means that first $item is expanded
    # to some value and then that value is treated as a name of a
    # variable that is expanded. Basically variables are exported
    # without the prefix. Once that is done the variable whos name is
    # stored in $item is removed from the environment.
    for item in "${!__FRIJA_@}"; do
        export "${item#__FRIJA_}"="${!item}"
        unset "${item}"
    done

    # Clean up by removing the iterator variable
    unset item
fi

# $1 is 'wordiness' and $2 is the command name to execute
if [[ "${1}" == "y" ]]; then
    echo "" 1>&2
    echo "Environment given to us" 1>&2
    echo "===============================" 1>&2
    /usr/bin/env 1>&2
    echo "===============================" 1>&2
    echo "" 1>&2

    type "${2}" 1>&2
    shift 1
    echo "Command to execute: exec '${*}'" 1>&2
    echo "Calling exec..." 1>&2
    echo "" 1>&2
else
    shift 1
fi

# Call the command with its options and/or arguments
exec "$@"
