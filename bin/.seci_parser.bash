# Note that all definitions are assumed to be "additive" where
# multiple values are separated by ':'. That is, if the same variable
# name occur multiple times (either wihin a single .seci file or
# across multiple files) then each new value found is prepended to any
# existing value, much like PATH is handled in Linux.
#
# Note that this means that the content of listed .seci files is
# additive and are added together in the given order.
#
# A .seci-file in turn uses a line- and column-based format where each
# column is separated by whitespace. Note that empty lines are allowed
# and lines starting with '#' are considererd to be comments. There
# are two types of variables (LOCAL and ORDINARY) that can be created
# and/or modified using an instruction. Depending on type of
# instruction it may be followed by one or more operands.
#
# Ordinary variables are made available after parsing has finished,
# but local variables are not. All ordinary variables are stored
# together with their values in the global associative array
# $COMMON_SECI_VARIABLES[], and those that have been marked using the
# export instruction are also stored in the global associative array
# $EXPORTED_SECI_VARIABLES[].
#
# In a .seci file the first column contain the instruction where the
# set of allowed instructions are
#
#
# conflict <symbol>
#
# Checks if the given <symbol> exist or not, if it does exist then an
# error is raised. If it does not exist then it is set to the name of
# the .seci-file. This works more or less as some kind of "include
# guard" in C/C++ header files (sanity check that the same kind of
# file is not read twice).
#
#
# local <name> <value>
#
# Defines given name as a LOCAL variable and assigns it the given
# value, that is the variable is NOT available after parsing of the
# .seci file; useful if the same value is repeated several times. A
# local variable value is expanded using plain Bash variable expansion
# notation; to insert the value of name use ${name}. Note that no
# other types of expansions are allowd and result in an error.
#
# Note that if the named variable already exist then an error is
# raised.
#
#
# set <name> <value>
#
# Defines given name as an ORDINARY variable that is assigned the
# given value. The value is expanded using plain Bash variable
# expansion notation; to insert the value of either a local or an
# ordinary variable use ${name}. Note that no other types of
# expansions are allowd and result in an error.
#
# Note that if the named variable already exist then an error is
# raised.
#
#
# export <name>
#
# Defines given name as an ORDINARY variable without assigning any new
# value to it and mark it as 'exported' at the same time. That is the
# variable name is stored in the $EXPORTED_SECI_VARIABLES[]
# associative array and the value is stored in the
# $COMMON_SECI_VARIABLES[] associative array.
#
#
# prepend <name> <value>
#
# If NO variable exist with the given name then an ORDINARY variable
# is created and assigned the given value just like the set command.
# If a variable with the given name DO exist, then the given value is
# PREPENDED (added at the front) to the expanded value with a ':'
# separator inserted in-between (Unix/Linux PATH separator). Note that
# if the variable was a LOCAL variable before the prepend instruction
# was executed then the instruction will transform it into an ORDINARY
# variable.
#
#
# append <name> <value>
#
# Very similar to prepend instruction with the only difference that
# the value is APPENDED (added at the end) instead of being prepended.
#
#
#
# Example .seci file
#
# conflict  gcc
# local     GCC_HOME          "/sw/gcc/4.9.4-shared/bin"
# prepend   PATH              "${GCC_HOME}"
# export    PATH
# prepend   LD_LIBRARY_PATH   "${GCC_HOME}/lib64"
# export    LD_LIBRARY_PATH
# set       CC                "gcc"
# set       CXX               "g++"
#
# After this .seci file has been parsed (assuming it was the first to
# be parsed)
#
# $COMMON_SECI_VARIABLES[]
#  [PATH]="/sw/gcc/4.9.4-shared/bin"
#  [LD_LIBRARY_PATH]="/sw/gcc/4.9.4-shared/bin/lib64"
#  [CC]="gcc"
#  [CXX]="g++"
#
# $EXPORTED_SECI_VARIABLES[]
#  [PATH]=""
#  [LD_LIBRARY_PATH]=""


# Variables that are marked as 'exported'
declare -A EXPORTED_SECI_VARIABLES=()

# List of all variables including those that have been marked as
# 'exported'.
declare -A COMMON_SECI_VARIABLES=()


function sanity_check_string()
{
    print_debug_enter "$@"
    local value="${1}"
    local regex="^[^$\`]*(([$][{][-a-zA-Z_0-9]+[}])*[^$\`]*)*$"
    local row="${2}"
    local filename="${3}"

    local message=""
    if [[ "${value}" =~ $regex ]]; then
        # $value is safe to evaluate; that is it contain zero or more
        # plain variable references using "${foobar}" notation, and
        # not trickery like $(foo) or `foo` that causes Bash to
        # execute something.
        :
    else
        message="Variable '${variable}' on row ${row} in '${secifile}' "
        message+="may not be assigned value ('${value}') since it has too "
        message+="complex variable references; only plain variable references "
        message+="using \${} notation is allowed, aborting."

        print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
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

    local message=""
    if [[ -v "${variable}" ]]; then
        local conflict="${conflictVariables[${variable}]:-}"
        if [[ -z "${conflict}" ]]; then
            if [[ "${WORDY:-}" == "y" ]]; then
                message="Creating conflict variable '${variable}' "
                message+="with value '${value}'"

                print_message "${message}"
            fi

            # Save a mapping between variable name $variable and value
            # $value
            conflictVariables["${variable}"]="${value}"
        else
            message="Conflict between SECI definitions found; "
            message+="conflict '${variable}' on row ${row} in '${secifile}' "
            message+="has already been defined in '${conflict}', aborting."

            print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
        fi
    else
        message="Conflict variable '${variable}' on row ${row} in "
        message+="'${secifile}' not declared in outer scope as expected, "
        message+="aborting."

        print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
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
    if [[ -v "${variable}" ]]; then
        if [[ -z "${!variable}" ]]; then
            sanity_check_string "${value}" "${row}" "${filename}"

            # Assign $value to the variable named in $variable. Note that
            # any variable references made in $value are expanded using
            # the $(eval echo ${value}) expression as that is a side
            # effect of variable expansion.
            #
            # shellcheck disable=SC2086
            eval "${variable}"="$(eval echo ${value})"

            # Add $variable to set of variables made available to for
            # instance a Makefile by adding it to the associative
            # array $COMMON_SECI_VARIABLES. Note that such a variable
            # might also be added to the set of "exported" variables
            # (listed in $EXPORTED_SECI_VARIABLES) using the 'export'
            # keyword in the .seci file.
            localVariables["${variable}"]="${!variable}"
        else
            message="Variable '${variable}' on row ${row} in '${secifile}' may "
            message+="not be assigned another value ('${value}') since it has "
            message+="already been assigned value '${!variable}', aborting."

            print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
        fi
    else
        local message="Variable '${variable}' on row ${row} in '${secifile}' "
        message+="not declared in outer scope as expected, aborting."

        print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
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
    if [[ -v "${variable}" ]]; then
        if [[ -z "${!variable}" ]]; then
            sanity_check_string "${value}" "${row}" "${filename}"

            # Assign $value to the variable named in $variable and
            # make it available to sub-processes
            #
            # At the same time make indirectly referenced variable
            # available to sub-processes.
            #
            # Note that any variable references made in $value are
            # expanded using the $(eval echo ${value}) expression as that
            # is a side effect of variable expansion.
            #
            # shellcheck disable=SC2086
            eval "${variable}"="$(eval echo ${value})"

            # Add $variable to set of variables made available to for
            # instance a Makefile by adding it to the associative
            # array $COMMON_SECI_VARIABLES. Note that such a variable
            # might also be added to the set of "exported" variables
            # (listed in $EXPORTED_SECI_VARIABLES) using the 'export'
            # keyword in the .seci file.
            COMMON_SECI_VARIABLES["${variable}"]="${!variable}"
        else
            message="Variable '${variable}' on row ${row} in '${secifile}' may "
            message+="not be assigned another value ('${value}') since it has "
            message+="already been assigned value '${!variable}', aborting."

            print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
        fi
    else
        message="Variable '${variable}' on row ${row} in '${secifile}' "
        message+="not declared in outer scope as expected, aborting."

        print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
    fi

    print_debug_exit
}


function process_export()
{
    print_debug_enter "$@"
    local variable="${1}"
    local row="${2}"
    local secifile="${3}"

    local message=""
    if [[ -v "${variable}" ]]; then
        # Ensure $variable is an ordinary variable
        COMMON_SECI_VARIABLES["${variable}"]="${!variable}"

        # Mark $variable also as exported by adding its name as a key
        # in the associative array $EXPORTED_SECI_VARIABLES[]. The
        # value is obtained from the $COMMON_SECI_VARIABLES[]
        # associative array.
        EXPORTED_SECI_VARIABLES["${variable}"]=""
    else
        message="Variable '${variable}' on row ${row} in '${secifile}' "
        message+="not declared in outer scope as expected, aborting."

        print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
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

    local message=""
    if [[ -v "${variable}" ]]; then
        if [[ -z "${!variable}" ]]; then
            # Assign $value to the variable named in $variable and at the
            # same time expand indirectly referenced variables before the
            # assignment.
            #
            # Note that any variable references made in $value are
            # expanded using the $(eval echo ${value}) expression as that
            # is a side effect of variable expansion.
            #
            # shellcheck disable=SC2086
            eval "${variable}=$(eval echo ${value})"
        else
            # Append $value; this is done by an indirect reference to
            # the variable name stored in $variable. That is, if
            # $foo="123" and $bar="foo", then "${!bar}" result in
            # "123" and not "foo" due to the '!' in front of the
            # variable name.
            #
            # At the same time expand indirectly referenced variables
            # before the assignment.
            #
            # shellcheck disable=SC2086,SC2140
            eval "${variable}"="${!variable}:$(eval echo ${value})"
        fi

        # Add $variable to set of variables made available to for
        # instance a Makefile by adding it to the associative array
        # $COMMON_SECI_VARIABLES. Note that such a variable might also
        # be added to the set of "exported" variables (listed in
        # $EXPORTED_SECI_VARIABLES) using the 'export' keyword in the
        # .seci file.
        COMMON_SECI_VARIABLES["${variable}"]="${!variable}"
    else
        message="Variable '${variable}' on row ${row} in '${secifile}' "
        message+="not declared in outer scope as expected, aborting."

        print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
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

    local message=""
    if [[ -v "${variable}" ]]; then
        if [[ -z "${!variable}" ]]; then
            # Assign $value to the variable named in $variable and at the
            # same time expand indirectly referenced variables before the
            # assignment.
            #
            # Note that any variable references made in $value are
            # expanded using the $(eval echo ${value}) expression as that
            # is a side effect of variable expansion.
            #
            # shellcheck disable=SC2086
            eval "${variable}"="$(eval echo ${value})"
        else
            # Prepend $value; this is done by an indirect reference to
            # the variable name stored in $variable. That is, if
            # $foo="123" and $bar="foo", then "${!bar}" result in
            # "123" and not "foo" due to the '!' in front of the
            # variable name.
            #
            # At the same time expand indirectly referenced variables
            # before the assignment.
            #
            # shellcheck disable=SC2086,SC2140
            eval "${variable}"="$(eval echo ${value}):${!variable}"
        fi

        # Ensure resulting variable is an ORDINARY variable
        COMMON_SECI_VARIABLES["${variable}"]="${!variable}"
    else
        message="Variable '${variable}' on row ${row} in '${secifile}' "
        message+="not declared in outer scope as expected, aborting."

        print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
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


    local message=""
    if [[ -z "${variable}" ]]; then
        message="Empty variable name found in '${secifile}' on "
        message+="row ${row}, aborting."

        # Print error message to stderr and exit with an error code
        print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
    fi

    # Create a local variable named $variable if it does not already
    # exist as a local variable. Due to that Bash uses call-by-name
    # this variable is made available to called functions. That is a
    # local variable behaves as a semi-global variable.
    #local "${variable}"

    case "${instruction}" in
        "conflict")
            # Conflict variable is not assigned via value from
            # .seci file, instead it is assigned the name of the
            # file that defines it. Thus we must check if $value
            # is non-empty and abort with an error message if that
            # is the case.
            if [[ -n "${value}" ]]; then
                message="Conflict declaration on row ${row} in '${filename}' "
                message+="may only define a symbol but must not give any "
                message+="additional parameters such as '${value}', aborting."

                # Print error message to stderr and exit with an error code
                print_error "${message}" \
                            "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
            fi

            process_conflict "${variable}" "${filename}" "${row}" "${filename}"
            ;;
        "local")
            if [[ "${WORDY:-}" == "y" ]]; then
                print_message "Local variable '${variable}'='${value}'"
            fi
            process_local "${variable}" "${value}" "${row}" "${filename}"
            ;;
        "set")
            if [[ "${WORDY:-}" == "y" ]]; then
                print_message "Set variable '${variable}'='${value}'"
            fi
            process_set "${variable}" "${value}" "${row}" "${filename}"
            ;;
        "append")
            if [[ "${WORDY:-}" == "y" ]]; then
                print_message "Append '${value}' to variable '${variable}'"
            fi
            process_append "${variable}" "${value}" "${row}" "${filename}"
            if [[ "${WORDY:-}" == "y" ]]; then
                print_message "  Result is '${!variable}'"
            fi
            ;;
        "prepend")
            if [[ "${WORDY:-}" == "y" ]]; then
                print_message "Prepend '${value}' to variable '${variable}'"
            fi
            process_prepend "${variable}" "${value}" "${row}" "${filename}"
            if [[ "${WORDY:-}" == "y" ]]; then
                print_message "  Result is '${!variable}'"
            fi
            ;;
        "export")
            if [[ "${WORDY:-}" == "y" ]]; then
                print_message "Export '${variable}' with '${!variable}'"
            fi
            # Mark variable as exported to the shell execution
            # environment. Variables that are neither local nor
            # exported are only made available to the make system via
            # the generated file created by the Frija generate
            # command, for instance FrijaGenerated.Makefilefragment.
            process_export "${variable}" "${row}" "${filename}"
            ;;
        *)
            message="Unknown instruction '${instruction}' found on row ${row} "
            message+="in '${filename}', aborting."

            # Print error message to stderr and exit with an error code
            print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
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
#
# WARNING: Calling this function will most likely hose global
# environment variables like PATH in the callers environment. This
# function does save and restore PATH environment variable, but others
# might also be affected that are not automatically restored. Due to
# this other vital parts of the environment might need to be saved
# before calling this function and then restored after the function
# call returns. See documentation for functions
# frija_save_environment() and frija_restore_environment() for further
# information.
function parse_seci_files()
{
    # Best effort in saving the current environment as we now it will
    # most likely be hosed by this function
    _frija_save_environment

    # Path to Frija build environment repo
    local buildEnvPath="${1:-}"

    # Version to select within Frija build environment repo; an empty
    # string is an error
    local buildEnvVersion="${2:-}"

    # List of comma-separated .seci-files to read from; may be an empty string
    local secilist="${3:-}"


    # Reset global variable EXPORTED_SECI_VARIABLES
    #
    # shellcheck disable=SC2034
    EXPORTED_SECI_VARIABLES=()

    # Reset global variable COMMON_SECI_VARIABLES
    #
    # shellcheck disable=SC2034
    COMMON_SECI_VARIABLES=()


    local message=""

    # If $seciList is empty there is no point in continuing. This can
    # happen for a repo that does not have any build environment and
    # is thus not an error, unless $buildEnvPath or $buildEnvVersion
    # are NOT empty.
    if [[ -z "${secilist}" ]]; then
        if [[ -z "${buildEnvPath}" ]] && [[ -z "${buildEnvVersion}" ]]
        then
            message="Given buildEnvPath is '${buildEnvPath}' and "
            message+="buildEnvVersion is '${buildEnvVersion}', but "
            message+="secilist (expected 3rd argument) is empty. "
            message+="Something is probably wrong with the repos file, "
            message+="aborting."

            # Print error message to stderr and exit with an error code
            print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
        else
            return "$_FRIJA_EXIT_OK"
        fi
    fi


    # Check if Frija build environment path is empty
    if [[ -z "${buildEnvPath}" ]]; then
        message="Given Frija build environment path (expected 1st argument) "
        message+="is an empty string.\\n"
        message+="Given arguments are: '$*'"

        # Print error message to stderr and exit with an error code
        print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
    fi


    # Check if given version is empty
    if [[ -z "${buildEnvVersion}" ]]; then
        message="Given version (expected 2nd argument) is an empty string.\\n"
        message+="Given arguments are: '$*'"

        # Print error message to stderr and exit with an error code
        print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
    fi


    if [[ "${WORDY:-}" == "y" ]]; then
        print_message "Using Frija build environment '${buildEnvPath}'" 1>&2
    fi

    # Used for checking if there is a conflict between .seci files via
    # the 'conflict' keyword.
    declare -A conflictVariables=()

    secifile=""
    declare -i row=0
    if [[ "${buildEnvVersion}" == "floating" ]]; then
        for seci in ${secilist//,/ }; do
            if [[ "${WORDY:-}" == "y" ]]; then
                print_message "------------" 1>&2
                print_message "Reading from '${seci}'" 1>&2
            fi
            secifile="${buildEnvPath}/SECI/${seci}"

            if [[ "${secifile}" != *"${FENSALIR_SECI_EXTENSION}" ]]
            then
                # shellcheck disable=SC2154
                message="Referenced SECI file '${secifile}' in '${inFile}' "
                message+="on row ${INFILE_ROWNUMBER} does not end with "
                message+="'${FENSALIR_SECI_EXTENSION}'."
                print_warning "${message}"
            fi


            # Create an alias to avoid shellcheck warning SC2094 as the
            # situation it warns about is not applicable and it seems
            # impossible to disable the check for the row redirecting
            # $secifile into the while loop...
            filename="${secifile}"

            if [[ -f "${filename}" ]]; then
                # Stores all local variables; needed for detecting if
                # a variable is not yet assigned a value or not.
                declare -A localVariables=()

                local probe=""
                while read -r instruction variable value rest
                do
                    # Strip any carriage returns from the read values
                    instruction=${instruction//$'\r'}
                    variable=${variable//$'\r'}
                    value=${value//$'\r'}

                    # Remember which row we are on; needed in error
                    # printouts
                    row=$(( row+1 ))

                    if [[ -z "${instruction}" ]] \
                           || [[ "${instruction}" == "#"* ]]
                    then
                        continue
                    fi

                    # First check if $variable is a local variable
                    # with default value set as the empty string.
                    probe="${localVariables[${variable}]:-}"

                    # Then check if it is a known ordinary variable
                    # with default value set to the previous value of
                    # $probe. That is the precendence order is
                    # ordinary variable > local variable > empty
                    # string.
                    probe="${COMMON_SECI_VARIABLES[${variable}]:-${probe}}"

                    # Ensure $variable exist in local scope; that is
                    # this function and all functions it calls will be
                    # able to find the variable depending on scope
                    # since Bash uses call by name semantics.
                    declare "${variable}"="${probe}"

                    process_instruction "${seci}" \
                                        "${row}" \
                                        "${instruction}" \
                                        "${variable}" \
                                        "${value}"
                done < "${secifile}"
            else
                message="Requested SECI file '${secifile}' "
                message+="(referenced by the input file) "
                message+="could not be found, aborting."

                # Print error message to stderr and exit with an error code
                print_error "${message}" \
                            "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
            fi
        done
    else
        # Read buildEnvVersion from Git-repo
        # Check if given tag exist in Frija build environment repo
        if git -C "${buildEnvPath}" \
                  show-ref --tags "${buildEnvVersion}" --quiet
        then
            # Read from given buildEnvVersion in Git repo
            for secifile in ${secilist//,/ }; do
                if [[ "${WORDY:-}" == "y" ]]; then
                    print_message "Reading from '${seci}'" 1>&2
                    print_message "------------" 1>&2
                fi
                # Build Git version specifier
                secifile="${buildEnvVersion}:${BUILD_CONF}/${secifile}"

                # Check if requested .seci-file exist for this version in Git
                if git -C "${buildEnvPath}" cat-file -e "${secifile}"
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
                    done < <(git -C "${buildEnvPath}" cat-file "${secifile}")
                else
                    message="Requested SECI file '${secifile}' "
                    message+="in Frija build environment '${buildEnvPath}' "
                    message+="and Git tag ${buildEnvVersion} "
                    message+="(referenced by the input file) "
                    message+="could not be found, aborting."

                    # Print error message to stderr and exit with an error code
                    print_error "${message}" \
                                "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
                fi
            done
        else
            message="Input file refers to tag '${buildEnvVersion}' in "
            message+="Frija build environment '${buildEnvPath}', alas this tag "
            message+="does not exist, aborting."

            # Print error message to stderr and exit with an error code
            print_error "${message}" "$_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS"
        fi
    fi

    # Best effort in restoring the current environment
    _frija_restore_environment
}
