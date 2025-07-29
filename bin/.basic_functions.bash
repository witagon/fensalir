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
# File is sourced by .core_config.bash and fensalir-config scripts.

################################################################################
# This file assumes variables $_FENSALIR_ROOT and $_FENSALIR_HOME are
# set.
################################################################################

if [[ -v _FRIJA_PROGRAM_PATH ]]; then
    # Remove longest matching prefix matching "*/", i.e. all paths up to
    # but not including the program name
    _FRIJA_PROGRAM_NAME="${_FRIJA_PROGRAM_PATH##*/}"

    # If command is "frija-build" then _FRIJA_NAME will be "build"
    _FRIJA_USAGE_NAME=${_FRIJA_PROGRAM_NAME//-/ }


    # Note: Command line parsing below relies on GNU getopt which is a
    # separate binary that canonicalizes the command line so it can be
    # more easily parsed and should not be confused with the Bash builtin
    # getopts which does not support long options and so on.

    # Ensure that we actually use GNU getopt
    # - Allow command to fail with !'s side effect on errexit
    # - Use return value from ${PIPESTATUS[0]}, because ! hosed $?
    ! getopt --test
    if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
	message="Aborting, GNU getopt not in search path."
	print_error "${message}" $_FRIJA_EXIT_GETOPT_NOT_FOUND
    fi


    # During TAB-completion the variable $_FENSALIR_CMD_NAME will be set
    # to the command name on the command line. On the other hand, when a
    # script is executed then it it won't be set to anything. To handle
    # this case we re-assign $_FENSALIR_CMD_NAME. In case
    # $_FENSALIR_CMD_NAME is empty then the value assigned is
    # $_FRIJA_PROGRAM_NAME with everything after (and including) the first
    # '-' removed.
    #
    # That is, if $_FENSALIR_CMD_NAME is empty and $_FRIJA_PROGRAM_NAME is
    # "frija-fnord" then ${_FRIJA_PROGRAM_NAME%%-*} expands to just
    # "frija".
    _FENSALIR_CMD_NAME="${_FENSALIR_CMD_NAME:-${_FRIJA_PROGRAM_NAME%%-*}}"


    # Ensure getopt is not working in compatible mode as this makes
    # parsing of optional arguments virtually impossible.
    unset -v GETOPT_COMPATIBLE

    ! _FRIJA_PARSED=$(getopt --options="${_FRIJA_SUBCOMMAND_OPTIONS}" \
                             --longoptions="${_FRIJA_SUBCOMMAND_LONGOPTS}" \
                             --name "${_FRIJA_USAGE_NAME}" \
                             -- "${@}")
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
	# E.g. return value is 1 Then getopt has complained to stdout
	#  about wrong arguments. Note that we rely on that Bash scripts
	#  are interpreted and that the function name is evaluated before
	#  it is called.
	_"${_FENSALIR_CMD_NAME}"_subcommand_usage;
	exit $_FRIJA_EXIT_GETOPT_NOT_FOUND
    fi

    # To handle quoting correctly in output from getopt we have to do this
    eval set -- "${_FRIJA_PARSED}"
fi



_VOLLA_HOME_FOLDER="volla"
_VOLLA_PATH=""

if [[ -v PWA && "${PWA}" != "" ]]; then
    _VOLLA_PATH="${PWA}/${_VOLLA_HOME_FOLDER}"
else
    # Set _VOLLA_PATH to $_FENSALIR_ROOT in case $PWA has not been
    # configured (case when bootstraping Fensalir installation).
    _VOLLA_PATH="${_FENSALIR_ROOT}"
fi


# Ensure $_FRIJA_PRINT_DEBUG exist as a variable and at the same time
# allow it to be set from the outside.
_FRIJA_PRINT_DEBUG="${_FRIJA_PRINT_DEBUG:-}"


# Snapshot of current PATH environment variable. This snapshot can be
# updated using the frija_save_environment() function, and restored
# using the complementary frija_restore_environment() function.
_FRIJA_SAVED_PATH="${PATH}"


# Save selected parts of the current environment.
function _frija_save_environment()
{
    _FRIJA_SAVED_PATH="${PATH}"
}


# Restore saved selected parts of the environment.
function _frija_restore_environment()
{
    PATH="${_FRIJA_SAVED_PATH}"
}


# Provide a common Bash option configuration function that set the
# following options
#
# errexit Bash exits if a command exits with a non-zero exit code
#
# pipefail Return value of a pipeline is the value of the last
#          (rightmost) command to exit with a non-zero status, or zero if all
#          commands in the pipeline exited successfully.
#
# noclobber Bash does not overwrite an existing file with the >, >&,
#           and <> redirection operators. May be overridden by using
#           >| instead of >.
#
# nounset Treat unset variables and parameters other than the special
#         parameters "@" and "*" as an error when performing parameter
#         expansion. If expansion is attempted on an unset variable or
#         parameter, the shell prints an error message, and, if not
#         interactive, exits with a non-zero status.
function _frija_configure_bash()
{
    # Ensure that all functions that call this function execute in an
    # environment where these Bash options are set
    set -o errexit -o pipefail -o noclobber -o nounset

    # NOTE: When Bash version 4.4+ is used this line can be
    # uncommented and ALL calls to this function from within other
    # functions can be safely removed.
    #
    # shopt -s inherit_errexit
}


# Get common exit code definitions
#
# shellcheck source=./.exit_codes.bash
source "${_FENSALIR_HOME}/.exit_codes.bash"


# Terminal width
# shellcheck disable=SC2034
! WIDTH=$(tput cols)
WIDTH="${WIDTH:-80}"

BOLD=""
ITALIC=""
REVERSE=""
UNDERLINE_ON=""
UNDERLINE_OFF=""
CLEAR=""

if [[ -z "${_FRIJA_NO_ESCAPES:-}" ]]; then
    # Begin bold mode ON sequence
    # shellcheck disable=SC2034
    ! BOLD=$(tput bold)
    BOLD="${BOLD:-$(echo -e \\e[1m)}"

    # Begin italic mode ON sequence. In case tput reports terminal does
    # not support italic mode we use VT100 escape sequence as a fallback.
    # For instance termcap for xterm terminal in CentOS 7.9 does not
    # report that italic mode is supported by the terminal even though it
    # actually is...
    # shellcheck disable=SC2034
    ! ITALIC=$(tput sitm)
    ITALIC="${ITALIC:-$(echo -e \\e[3m)}"

    # Begin reverse video ON mode sequence
    # shellcheck disable=SC2034
    ! REVERSE=$(tput rev)
    REVERSE="${REVERSE:-$(echo -e \\e[7m)}"

    # Begin underline ON mode sequence
    # shellcheck disable=SC2034
    ! UNDERLINE_ON=$(tput smul)
    UNDERLINE_ON="${UNDERLINE_ON:-$(echo -e \\e[4m)}"

    # Begin underline OFF mode sequence
    # shellcheck disable=SC2034
    ! UNDERLINE_OFF=$(tput rmul)
    UNDERLINE_OFF="${UNDERLINE_OFF:-$(echo -e \\e[24m)}"

    # Clear all attributes
    # shellcheck disable=SC2034
    ! CLEAR=$(tput sgr0)
    CLEAR="${CLEAR:-$(echo -e \\e[0m)}"
fi




# This function return an expression that can be evaluated to reset
# GLOBIGNORE to its current value. That is, first call this function
# and save the result. Change GLOBIGNORE to whatever you want. And
# then evaluate the returned expression to reset GLOBIGNORE back to
# whatever it was before you changed it.
#
# This is a perfect match for a trap expression, where the trap will
# execute an expression when a certain event happens. For instance
# when a function call returns.
#
# Thus you can do
#
# function foo()
# {
#     trap "$(_frija_restore_globignore_expression)" RETURN
#     GLOBIGNORE="foobar*"
#     # Do something
# }
#
# This will first save the current state of GLOBIGNORE via the trap,
# then change GLOBIGNORE and do something. When the function returns
# (for whatever reason) the value of GLOBIGNORE will be restored to
# its saved value.
function _frija_restore_globignore_expression()
{
    if [[ -v GLOBIGNORE ]]; then
        # Save current value in returned expression
        echo eval GLOBIGNORE="\"${GLOBIGNORE}\""
    else
        # Unset GLOBIGNORE in returned expression, since it was unset
        # when this function was called
        echo unset -v GLOBIGNORE
    fi
}


# This function return an expression that can be evaluated to reset
# extended globbing expression to its current value. That is, first
# call this function and save the result. Change extended globbing
# state to whatever you want. And then evaluate the returned
# expression to reset extended globbing state back to whatever it was
# before you changed it.
function _frija_restore_extglob_expression()
{
    if shopt -q extglob; then
        # Set extended globbing in returned expression, since it was
        # set when this function was called
        echo shopt -s extglob
    else
        # Unset extended globbing in returned expression, since it was
        # unset when this function was called
        echo shopt -u extglob
    fi
}


# Very basic function that echoes a message to stderr.
function _frija_echo()
{
    echo -e "${1}" 1>&2
}


# Very basic function that echoes a message to stderr provided that
# the GLOBAL variable $_FRIJA_PRINT_DEBUG is set to 'y'. This function
# is used when print_debug() can't be used. For instance,
# print_debug() calls _frija_fold() which means that _frija_fold()
# can't rely on print_debug() for debug printouts...
function _frija_dcho()
{
    if [[ "${_FRIJA_PRINT_DEBUG}" == "y" ]]; then
        echo -e "${1}" 1>&2
    fi
}


# Preferred minimum width of body text when folding a message. Highest
# priority is to try to preserve at least this width when folding
# text. This means that any outdents and indents go first before the
# body width is reduced beyond this value.
declare -i _FRIJA_MIN_WIDTH=30


# Fold a string so it either fits within a terminal window (provided
# that $WIDTH can be assigned a meaningful value) or to a specified
# width. Furthermore it is possible to indent the string given number
# of characters.
#
# Any VT100 escape sequences embedded in the string are ignored when
# calculating where to force linebreaks, and any embedded ANSI-C
# quoting sequences are passed through and their width is considered
# to be one character. Alas multicharacter sequences are not
# guaranteed to be unscathed by the folding logic; newlines may be
# inserted in the middle of them...
#
# First parameter is the message itself to fold
#
# Second (optional) parameter is the indent in number of characters to
# reserve space on the left hand side from the width of the terminal
# window. Default is 0 (zero) characters of indent.
#
# Third (optional) parameter is the width to use when folding. Default
# width is the terminal width, and if it couldn't be determined 80
# characters is the fallback value.
#
# Fourth (optional) value is hanging text for an outdent of the first
# line of the folded text. This is given as the text to use as the
# hanging outdent, for instance "Note:". A space is added to the end
# of the text and the number of charaacters in the given text plus one
# is added to the indent value. Default value is the empty string.
function _frija_fold()
{
    local message="${1}"

    # Indent of folded message
    declare -i indent="${2:-0}"

    # Indent of all lines after first line
    declare -i bodyIndent=${indent}

    # Width to use when folding
    declare -i width="${3:-${WIDTH:-80}}"

    # Optional outdent "heading", for instance "Note:" or "Warning:"
    local outdent="${4:-}"
    declare -i outdentWidth=0

    #_FRIJA_PRINT_DEBUG="y"
    if [[ "${_FRIJA_PRINT_DEBUG}" == "y" ]]; then
        _frija_dcho "outdent=${outdent}"
        _frija_dcho "indent=${indent}"
        _frija_dcho "width=${width}"
        _frija_dcho "--- Input ----"
        od -A x -t x1z -v <<< "${message}" 1>&2
        _frija_dcho "--------------"
    fi

    if [[ -n "${outdent}" ]]; then
        # A hanging text outdent has been provided, add a space at the
        # end to this text while ensuring that any spaces provided at
        # the start or end of $outdent are first removed.
        outdent="${outdent/#*( )/}"
        outdent="${outdent/%*( )/} "

        # Enable extended globbing support in Bash and restore its
        # state to whatever it was when function return. Extended
        # globbing means that you can write globbing expressions like
        # *(foo) that match zero or more occurrences of 'foo'.
        #
        # shellcheck disable=SC2064
        trap "$(_frija_restore_extglob_expression)" RETURN
        shopt -s extglob

        # Remove all VT100 escape sequences from $outdent
        local plain="${outdent//$'\e'[\[(]*([0-9;])[@-n]/}"

        # Now we can calculate the real width (as shown in terminal)
        # of string
        declare -i outdentWidth=${#plain}
    fi

    _frija_dcho "outdent='${outdent}'"
    _frija_dcho "outdentWidth='${outdentWidth}'"

    local padding=""
    local bodyPadding=""

    _frija_dcho "width='${width}'"
    _frija_dcho "_FRIJA_MIN_WIDTH='${_FRIJA_MIN_WIDTH}'"

    # Adjust indent if necessary to ensure that the body text gets as
    # much space as possible
    if (( indent > 0 )); then
        if (( width < indent )); then
            if (( width > _FRIJA_MIN_WIDTH )); then
                indent=$(( width - _FRIJA_MIN_WIDTH ))
                _frija_dcho "A: indent='${indent}'"
            else
                indent=0
                _frija_dcho "B: indent='${indent}'"
            fi
        else
            if (( width > _FRIJA_MIN_WIDTH )); then
                if (( (indent+_FRIJA_MIN_WIDTH) > width )); then
                    indent=$(( width - _FRIJA_MIN_WIDTH ))
                    _frija_dcho "C: indent='${indent}'"
                else
                    #indent=0
                    _frija_dcho "D: indent='${indent}'"
                fi
            else
                indent=0
                _frija_dcho "E: indent='${indent}'"
            fi
        fi
    fi

    _frija_dcho "indent='${indent}'"

    if (( indent >= 0 )) && (( indent < width )); then
        # Assume it is possible to indent wrapped text by $indent +
        # $outdentWidth spaces, except for first line which is
        # controlled by just $indent
        declare -i preliminaryWidth=$(( width - indent - outdentWidth ))

        if (( preliminaryWidth < _FRIJA_MIN_WIDTH )); then
            if (( preliminaryWidth > 0 )); then
                # Make part of $outdent "glide" into message to
                # preserve $_FRIJA_MIN_WIDTH of body width in message

                declare -i overshoot=$(( _FRIJA_MIN_WIDTH - preliminaryWidth ))
                declare -i newOutdentWidth=0
                if (( overshoot < outdentWidth )); then
                    newOutdentWidth=$(( outdentWidth - overshoot ))
                elif (( (overshoot-outdentWidth) < indent )); then
                    # Possible to reduce indent to preserve a body
                    # width of at least $_FRIJA_MIN_WIDTH characters
                    indent=$(( indent - (overshoot-outdentWidth) ))
                else
                    indent=0
                fi

                _frija_dcho "overshoot=${overshoot}"
                _frija_dcho "newOutdentWidth=${newOutdentWidth}"

                # Prepend end of $outdent to $message, and strip any
                # leading spaces from $message when it is expanded
                local suffix="${outdent:newOutdentWidth}"
                message="${suffix}${CLEAR}${message/#*( )/}"
                _frija_dcho "####: Outdent ('${suffix}') prepended to message."
                outdent="${BOLD}${outdent:0:newOutdentWidth}"

                if [[ "${suffix}" == " " ]]; then
                    # Compensate for initial space stripping of
                    # $message in main loop below
                    outdent+=" "
                    _frija_dcho "Outdent space-suffix compensated."
                fi

                outdentWidth=$(( newOutdentWidth ))
            else
                # Make whole $outdent "glide" into message to
                # preserve $_FRIJA_MIN_WIDTH of body width in message
                outdentWidth=0
                preliminaryWidth=$(( width - indent ))

                if (( preliminaryWidth < _FRIJA_MIN_WIDTH )); then
                    # Also consume a part of $indent
                    indent=$(( indent - (_FRIJA_MIN_WIDTH-preliminaryWidth) ))
                    if (( indent < 0 )); then
                        # No, consume all of $indent as well!
                        indent=0
                    fi
                fi

                # Prepend $outdent to $message, and strip any leading
                # spaces from $message when it is expanded
                message="${BOLD}${outdent}${CLEAR}${message/#*( )/}"
                _frija_dcho "####: Outdent ('${outdent}') prepended to message."
                outdent=""
            fi
        else
            _frija_dcho "Whole outdent ('${outdent}') bolded"
            # Ensure the outdent is bolded
            outdent="${BOLD}${outdent}${CLEAR}"
        fi

        bodyIndent=$(( indent + outdentWidth ))

        # After any adjustments above we can re-calculate the new
        # width. Indent wrapped text by $indent + $outdentWidth
        # spaces, except for first line which is controlled by just
        # $indent
        width=$(( width - indent - outdentWidth ))
        _frija_dcho "####: Using width=${width}"
        _frija_dcho "      (indent=${indent}, outdentWidth=${outdentWidth})"

        # Padding for first line. Padding string is created using
        # printf built-in command where '*' is a computed repeated
        # sequence where the number of spaces precedes the string to
        # indent; here we indent the empty string to get the padding.
        padding=$(printf "%*s" "${indent}" "")
        _frija_dcho "####: Using padding='${padding}'"

        if (( bodyIndent > indent )); then
           bodyPadding=$(printf "%*s" "${bodyIndent}" "")
        else
            bodyPadding=${padding}
        fi
        _frija_dcho "####: Using bodyPadding='${bodyPadding}'"
    fi

    # $count is where the cursor is within the current line
    declare -i count=0

    # $escapeCount is where the cursor is within the current line when
    # an escape sequence has been found
    declare -i escapeCount=0

    # $buffer is what is to be sent to the terminal after folding is
    # done
    local buffer=""

    if [[ -n "${outdent}" ]]; then
        # Insert the padding plus the outdent for the first line
        buffer="${padding}${outdent}"
    else
        # Just insert the padding since no outdent has been provided
        buffer="${bodyPadding}"
    fi

    # Temporary buffer used when an escape sequence has been found
    local escapeBuffer=""

    # Current "word", that is a sequence delimited by spaces
    local word=""

    # Current "word", that is a sequence delimited by spaces, when an
    # escape sequence has been found
    local escapeWord=""

    # The escape sequence that has been found
    local escapeSequence=""

    # Read one character at a time from the given message and parse
    # the content, that is any VT100 escape sequences etc. When
    # appropriate insert forced newlines to wrap the text in the
    # terminal.
    while IFS="" read -r -N1 character; do
        case "${character}" in
            $'\e'|" ")
                _frija_dcho "Found Escape or SPACE"

                declare -i length=${#word}
                if (( count > width )); then
                    # Insert a forced line break

                    _frija_dcho "count > width  (${count}>${width})"
                    _frija_dcho "newline"
                    _frija_dcho "word='${word}' (${length} characters)"

                    if (( length > width )); then
                        _frija_dcho "length > width (${length}>${width})"

                        # Number of characters to add BEFORE forced
                        # line break; compensate also for SPACE
                        declare -i before=$(( width - (count-length) ))

                        # Number of characters to add AFTER forced
                        # line break
                        declare -i after=$(( (length) - before ))

                        local start="${word:0:before}"
                        local end="${word:before}"

                        _frija_dcho "start='${start}'"
                        _frija_dcho "end='${end}'"
                        _frija_dcho "after='${after}'"
                        buffer+="${escapeSequence}${start}\\n"
                        escapeSequence=""
                        # shellcheck disable=SC2028
                        _frija_dcho "'${start}\\\\n' added"

                        _frija_dcho "Looping over end ('${end}')"
                        # Iterate over the remainder of the overlong
                        # word. Note that the loop will only execute
                        # the body for all subparts that are exactly
                        # $width wide. If less than the requested
                        # number of characters are available to read
                        # then the body will not be executed for that
                        # portion. Hence the IF-statement AFTER the
                        # wile-loop...
                        local line=""
                        while read -r -N${width} line; do
                            # Decrement $after with what we just read
                            after=$(( after - width ))

                            buffer+="${bodyPadding}${line}\\n"
                            # shellcheck disable=SC2028
                            _frija_dcho "'${bodyPadding}${line}\\\\n' added"
                        done <<< "${end}"

                        if (( after > 0 )); then
                            # A newline character is appended to the
                            # end of the read remainder which has to
                            # be trimmed. This is done using a simple
                            # parameter expansion with string
                            # replacement that replaces all '\n'
                            # (expressed as $'\n' in Bash) with
                            # nothing.
                            line="${line%%*($'\n')}"
                            buffer+="${bodyPadding}${line}"
                            _frija_dcho "'${bodyPadding}${line}' added"
                        else
                            buffer+="${bodyPadding}"
                            _frija_dcho "'${bodyPadding}' added"
                        fi

                        count=$(( after ))
                        _frija_dcho "count=${count}"
                    else
                        _frija_dcho "length <= width (${length} <= ${width})"
                        buffer+="\\n${bodyPadding}${escapeSequence}${word}"
                        escapeSequence=""
                        count=${length}

                        # shellcheck disable=SC2028
                        _frija_dcho "'\\\\n${bodyPadding}${word}' added"
                    fi
                else
                    _frija_dcho "count <= width  (${count} <= ${width})"

                    # Safe to insert complete word in buffer + SPACE
                    _frija_dcho "add '${word}' (${count} <= ${width})"

                    buffer+="${escapeSequence}${word}"
                    escapeSequence=""
                    _frija_dcho "'${word}' inserted"
                fi

                # As $word has been inserted it must be reset to empty
                # string
                word=""

                if [[ "${character}" == " " ]]; then
                    _frija_dcho "Found SPACE"
                    if (( count == width )); then
                        _frija_dcho "At end of line, forcing line break"
                        buffer+="\\n${bodyPadding}"
                        count=0
                    elif (( count > 0 )); then
                        buffer+=" "
                        count+=1
                        _frija_dcho "count=${count} ('${character}', '${word}')"
                    else
                        _frija_dcho "Ignoring initial space"
                    fi
                else
                    _frija_dcho "Found ESC"
                    # Double bookkeeping; $escapeSequence contain what
                    # we hope is an acutal escape sequence, and
                    # $escapeBuffer in combination with $escapeCount
                    # and $escapeWord implement a shadow world where
                    # the escape seuence turn out to not be a valid
                    # sequence and is instead treated as a "word" that
                    # is brutally splitted whenever the terminal width
                    # is reached. It is also due to this that the
                    # escape character (0x1b) is not added to
                    # $escapeWord (to make the sequence visible).
                    escapeSequence="${character}"

                    # As $escapeBuffer is appended to $buffer in case
                    # the sequence turn out to not be a valid escape
                    # sequence there is no need to initialize it to
                    # anything else than the empty string; it
                    # piggybacks on whatever is in the buffer.
                    escapeBuffer=""
                    escapeWord=""
                    escapeCount=${count}

                    # Read assumed initial [ or (
                    IFS="" read -r -N1 character

                    escapeSequence+="${character}"

                    escapeCount+=1
                    if (( escapeCount > width )); then
                        # Insert a forced line break
                        escapeBuffer+="${escapeWord}"
                        escapeBuffer+="\\n${bodyPadding}"
                        escapeWord=""
                        escapeCount=1
                    fi
                    escapeWord+="${character}"

                    if [[ "${character}" == [\[\(] ]]; then
                        # We are still within a valid VT100 escape
                        # sequence found, copy optional digits
                        # separated with ';'
                        while IFS="" read -r -N1 character; do
                            case "${character}" in
                                [0-9\;] )
                                    escapeSequence+="${character}"

                                    escapeCount+=1
                                    if (( escapeCount > width )); then
                                        # Insert a forced line break
                                        escapeBuffer+="${escapeWord}"
                                        escapeBuffer+="\\n${bodyPadding}"
                                        escapeWord=""
                                        escapeCount=1
                                    fi
                                    escapeWord+="${character}"

                                    continue
                                    ;;
                                *)
                                    break
                                    ;;
                            esac
                        done

                        # Finally check that the character at the end
                        # of the sequence is within the range [@-n],
                        # otherwise it is not a valid VT100 escape
                        # sequence.
                        if [[ "${character}" == [@-n] ]]; then
                            # Escape sequence ended!
                            _frija_dcho "ESC-sequence ended (${escapeWord})"

                            # Insert whole escape sequence in the
                            # buffer and we are finished with it!
                            escapeSequence+="${character}"
                            #buffer+="${escapeSequence}"
                        else
                            _frija_dcho "Non-ESC-sequence ended (${escapeWord})"

                            escapeCount+=1
                            if (( escapeCount > width )); then
                                # Insert a forced line break
                                escapeBuffer+="${escapeWord}"
                                escapeBuffer+="\\n${bodyPadding}"
                                escapeWord=""
                                escapeCount=1
                            fi
                            escapeWord+="${character}"

                            buffer+="${escapeBuffer}"
                            word="${escapeWord}"
                            count=${escapeCount}
                        fi
                    fi
                fi
                ;;
            "\\")
                _frija_dcho "Found \\"
                _frija_dcho "count=${count} ('${character}', '${word}')"

                # NOTE: This code may break \nnn and similar escape
                # sequences that are longer than backslash plus one
                # character by inserting a "\n" sequence in the middle
                # of them.
                word+="${character}"
                IFS="" read -r -N1 character
                case "${character}" in
                    "n")
                        word+="${character}${bodyPadding}"
                        screenWord+="${character}${bodyPadding}"
                        count=0
                        ;;
                    "\\")
                        count+=1
                        ;;
                    *)
                        word+="${character}"
                        screenWord+="${character}"
                        count+=1
                        ;;
                esac

                _frija_dcho "\\-sequence ended"
                _frija_dcho "count=${count} ('${character}', '${word}')"
                ;;
            *)
                count+=1
                word+="${character}"

                _frija_dcho "count=${count} ('${character}', '${word}')"
                ;;
        esac
    done <<< "${message}"

    _frija_dcho "After main while loop"

    # Add any lingering escape sequence to the buffer
    buffer+="${escapeSequence}"
    escapeSequence=""

    # Strip any trailing newline character
    word="${word/%$'\n'/}"
    count=$((count-1))
    _frija_dcho "word='${word}'"
    _frija_dcho "count='${count}'"
    _frija_dcho "width='${width}'"

    # There might be a word left when end of file was reached. Borrow
    # from space character handling logic above to insert it into the
    # buffer.

    declare -i length=${#word}
    _frija_dcho "length of '${word}' is ${length} characters"
    declare -i after=0
    local line=""
    if (( count > width )); then
        _frija_dcho "count > width  ( ${count}>${width})"

        # Number of characters to add BEFORE forced
        # line break; compensate also for SPACE
        declare -i before=$(( width - (count-length) ))
        _frija_dcho "before='${before}'"

        # Number of characters to add AFTER forced
        # line break
        _frija_dcho "length='${length}'"
        _frija_dcho "before='${before}'"
        after=$(( length - before ))
        _frija_dcho "after='${after}'"

        local start="${word:0:before}"
        local end="${word:before}"
        end="${end/%$'\n'/}"

        # Strip any trailing newline characters
        end="${end%%*($'\n')}"

        _frija_dcho "start='${start}'"
        _frija_dcho "end='${end}'"
        _frija_dcho "after='${after}'"
        buffer+="${escapeSequence}${start}\\n"
        escapeSequence=""
        # shellcheck disable=SC2028
        _frija_dcho "'${start}\\\\n' added"

        _frija_dcho "Looping over end ('${end}'), after=${after}"
        # Iterate over the remainder of the overlong word. Note that
        # '-n${width}' means "up to $width" characters where as
        # '-N${width}' means "EXACTLY $width" characters or no
        # characters at all.
        _frija_dcho "width='${width}'"
        while read -r -n${width} line; do
            # Decrement $after with what we just read
            after=$(( after - width ))
            _frija_dcho "after=${after}"

            line="${line%%*($'\n')}"
            buffer+="${bodyPadding}${line}\\n"
            # shellcheck disable=SC2028
            _frija_dcho "'${bodyPadding}${line}\\\\n' added"
        done <<< "${end}"

        _frija_dcho "After loop, after=${after}"
    else
        _frija_dcho "count <= width  ( ${count}<=${width})"
        buffer+="${word}\\n"
        #buffer+="${word}"
        # shellcheck disable=SC2028
        _frija_dcho "'${word}\\\\n' added"
    fi

    if [[ "${_FRIJA_PRINT_DEBUG}" == "y" ]]; then
        _frija_dcho "--- Output ---" 1>&2
        od -A x -t x1z -v <<< "${buffer}" 1>&2
        _frija_dcho "--------------" 1>&2
    fi

    # shellcheck disable=SC2059
    printf '%b' "${buffer}" 1>&2

    if [[ -n "${_FRIJA_IS_SOURCED:-}" ]]; then
        # Force bash to redraw prompt when within TAB-completion
        _frija_redraw_current_line
    fi
}


# Note: Indentation does is NOT aware of any difference between escape
# sequences and ordinary text. That is, escape sequence characters are
# counted as normal characters and thus affect where line breakes are
# inserted...
#
# First parameter is message to print.
#
# Second (optional) parameter is indentation
#
# Third (optional) parameter is width; when no width is specified the
# value of $WIDTH is used (usually set by shell) and if no value is
# assigned to $WIDTH then the fallback of 80 characters is used.
function print_message()
{
    local message="${1:-}"
    declare -i indent="${2:-0}"
    declare -i width="${3:-${WIDTH:-80}}"

    #echo "Q" 1>&2
    _frija_fold "${message}" "${indent}" "${width}"
    #echo "Q" 1>&2

#    if (( indent > 0 )) && (( indent < width )); then
#        # Indent wrapped text by $indent spaces provided that $indent
#        # is not greater than the terminal width. This is done first
#        # by reducing $WIDTH by $indent and then piping the result
#        # through sed that inserts the padding.
#        width=$(( width - indent ))
#        echo "####: Using width='${width}'"
#
#        # Padding string is created using printf built-in command
#        # where '*' is a computed repeated sequence where the number
#        # of spaces precedes the string to indent; here we indent the
#        # empty string to get the padding.
#        local padding=""
#        padding=$(printf "%*s" "${indent}" "")
#        echo "####: Using padding='${padding}'"
#
#        # Replace all line starts ('^') with the padding using sed
#        fold --spaces --width="${width}"<<<"${message}" | \
#            sed -e "s/^/${padding}/" >&2
#    else
#        # Ensure formatted text wraps nicely to terminal width and
#        # redirect to stderr
#        fold --spaces --width="${width}"<<<"${message}" >&2
#    fi
}


# Given two arguments (paths) the function return the relative path
# between the two given paths.
#
# First argument: The path something should be relative to.
#
# Second argument: The second path that the first path should be relative to.
function relative_path_to()
{
    local path="${1}"
    local name="${path##*/}"
    local relativeTo="${2:-${PWD}}"

    # Path to where Volla-folder is located
    local basePath="${_VOLLA_PATH%/*}"

    print_debug "path='${path}'"
    print_debug "name='${name}'"
    print_debug "relativeTo='${relativeTo}'"
    print_debug "basePath='${basePath}'"

    # Restore PATH in case it has been hosed for some reason.
    _frija_restore_environment

    # Only get a relative path when given $path and $relativeTo both
    # are below $basePath, otherwise an absolute path is returned.
    # Also request that no symlinks are followed in order to eliminate
    # for instance "/p/pwa/fnord" being turned into
    # "/p/pwa-user/7/fnord".
    path=$(realpath --no-symlinks \
                    --relative-base="${basePath}" \
                    --relative-to="${relativeTo}" \
                    "${path}")

    print_debug "path='${path}'"

    if [[ "${path}" == "${name}" ]]; then
        # Path is name itself; we have to add "./"
        # in front of it
        path="./${path}"
    elif [[ ! ("${path}" == "../"* || "${path}" == "/"*) ]]; then
        # Path to  is neither a relative path nor an absolute
        # path; make it a relative path originating from $PWD
        path="./${path}"
    fi

    echo "${path}"
}


function _frija_print_stack_trace()
{
    local exitcode="${1}"

    declare -i extraIndent=0

    local message=""

    if  (( BASH_SUBSHELL < 2 )); then
        print_double_separator
        message="Command "
    else
        print_separator
        extraIndent=2
        message="Subshell "
    fi

    message+="exited with exit code ${exitcode}: Stack trace"
    print_message "${message}" "${extraIndent}"

    # Renumber the arrays if they were sparse (which they might be)
    local sourcetrace=("${BASH_SOURCE[@]}")
    local functrace=("${FUNCNAME[@]}")
    local linetrace=("${BASH_LINENO[@]}")

    declare -i lastFuncIndex=$(( ${#functrace[@]} - 1 ))
    declare -i lastLineIndex=$(( ${#linetrace[@]} - 1 ))
    # Heuristics to make stack trace sane
    if (( lastFuncIndex == lastLineIndex )) \
           && (( lastFuncIndex > 0 )) \
           && (( linetrace[lastLineIndex] == 0 )) \
           && [[ "${functrace[${lastFuncIndex}]}" == "main" ]]
    then
        functrace=("${functrace[@]}::${lastFuncIndex}")
        linetrace=("${linetrace[@]}::${lastLineIndex}")

        # Remove second last source item
        declare -i lastSourceIndex=$(( ${#sourcetrace[@]} - 1 ))
        unset "sourcetrace[$((lastSourceIndex-1))]"

        # Renumber elements after deletion to get consecutive
        # numbering
        sourcetrace=("${sourcetrace[@]}")
    else
        message="When you see this message something went horribly wrong when "
        message+="printing a stack-trace. This is most likely due to a bug. "
        message+="Some vital debug printouts follow this message."
        print_warning "${message}"
        print_separator "Start of debug printouts" "${BOLD}"
        print_message "linetrace[0]=${linetrace[0]}" 2
        print_message "functrace[0]=${functrace[0]}" 2
        declare -p functrace 1>&2
        declare -p linetrace 1>&2
        print_separator "End of debug printouts" "${BOLD}"
    fi

    declare -i indent=2
    if (( BASH_SUBSHELL > 1 )); then
        (( indent+=extraIndent))
    fi

    declare -i index=0
    for (( index=${#sourcetrace[@]}-1 ; index>=0 ; index-- ));
    do
        if (( index > 0 )); then
            local func="${BOLD}${functrace[$index]}${CLEAR}"
            local linenumber="${linetrace[$index]}"
            local sourcefile=""
            sourcefile=$(relative_path_to "${sourcetrace[$index]}")
            print_message "at ${func}(${sourcefile}:${linenumber})" "${indent}"
        fi
    done

    if  (( BASH_SUBSHELL < 2 )); then
	if [[ -v _FRIJA_USAGE_NAME ]]; then
            print_separator
	fi
    fi
}


# If TAB completion is active force Bash prompt to be redrawn
function _frija_redraw_current_line()
{
    if [[ -v COMP_TYPE ]]; then
        print_debug "COMP_TYPE='${COMP_TYPE}'"
        # Force Bash to redraw the command line prompt by signaling a
        # (terminal) window size change that causes readline to redraw
        # the prompt.
        kill -WINCH "$$"
    fi
}


function _frija_completion_help_message()
{
    local helpMessage="${1}"

    # Prefix help message with name of frija command (in bold)
    local message="${BASH_SOURCE[1]##*/}"
    message="${BOLD}${message/-/ }:${CLEAR} ${helpMessage}"

    _frija_echo ""
    _frija_echo ""
    _frija_echo "${message}"
    _frija_redraw_current_line
}


function _frija_completion_note_message()
{
    local noteMessage="${1}"

    # Prefix note message with name of frija command (in bold)
    local message="${BASH_SOURCE[1]##*/}"
    message="${BOLD}${message/-/ }: ${UNDERLINE_ON}Note${CLEAR}: "
    message+="${noteMessage}"

    _frija_echo ""
    _frija_echo ""
    _frija_echo "${message}"
    _frija_redraw_current_line
}


function _frija_completion_warning_message()
{
    local warningMessage="${1}"

    # Prefix warning message with name of frija command (in bold)
    local message="${BASH_SOURCE[1]##*/}"
    message="${BOLD}${message/-/ }: ${UNDERLINE_ON}WARNING${CLEAR}: "
    message+="${warningMessage}"

    _frija_echo ""
    _frija_echo ""
    _frija_echo "${message}"
    _frija_redraw_current_line
}


function _frija_completion_error_message()
{
    local errorMessage="${1}"

    # Prefix error message with name of frija command (in bold)
    local message="${BASH_SOURCE[1]##*/}"
    message="${BOLD}${message/-/ }: ${UNDERLINE_ON}ERROR${CLEAR}: "
    message+="${errorMessage}"

    _frija_echo ""
    _frija_echo ""
    _frija_echo "${message}"
    _frija_redraw_current_line
}


function _frija_print_error()
{
    local message="${1}"
    declare -i exitcode=${2}
    local noExit="${3:-}"

    if [[ -n "${message}" ]]; then
        declare -i extraIndent=0

        if  (( BASH_SUBSHELL < 2 )); then
            _frija_print_stack_trace "${2:-}"
            print_separator ""
        else
            extraIndent=2
            print_double_separator
        fi

        if [[ $exitcode -eq 3 ]]; then
            _frija_fold "${message}" "${extraIndent}" "" "INTERNAL ERROR:"
        else
            _frija_fold "${message}" "${extraIndent}" "" "Error:"
        fi

        if  (( BASH_SUBSHELL < 2 )); then
	    if [[ -v _FRIJA_USAGE_NAME ]]; then
		print_separator
		print_message
		message="Try '${BOLD}${_FRIJA_USAGE_NAME} --help${CLEAR}' "
		message+="for more information."
		print_message "${message}"
		print_message
	    fi
        else
            _frija_print_stack_trace "${2:-}"
        fi
    else
        _frija_print_stack_trace "${2:-}"
    fi

    if [[ -z "${_FRIJA_IS_SOURCED:-}" ]] && [[ -z "${noExit}" ]]; then
        #print_message "Calling exit..."
        #local message="${BOLD}*** ${BASH_SOURCE[1]}  "
        #message+="${FUNCNAME[2]}():${BASH_LINENO[1]}"
        #message+="-->${FUNCNAME[1]}():${BASH_LINENO[0]}${CLEAR}  ${*}"
        #print_message "${message}"
        #local array_data=""
        #array_data=$(declare -p "BASH_SOURCE")
        #print_message "${array_data}"
        #array_data=$(declare -p "FUNCNAME")
        #print_message "${array_data}"
        #array_data=$(declare -p "BASH_LINENO")
        #print_message "${array_data}"

        # Only exit when top level script is NOT sourced
        exit "${exitcode}"
    else
        #print_message "Calling return..."
        # Force a stack trace to be printed to the terminal
        _frija_print_stack_trace "${exitcode}"
        _frija_redraw_current_line

        return "${exitcode}"
    fi
}


function print_error()
{
    #print_message "\$BASH_SOURCE[0]='${BASH_SOURCE[0]}'"
    #print_message "\$0='${0}'"
    #print_message "\${0##*/}='${0##*/}'"
    #print_message "\${BASH##*/}='${BASH##*/}'"
    #print_message "_FRIJA_IS_SOURCED='${_FRIJA_IS_SOURCED}'"

    if [[ "${0##*/}" == "${BASH##*/}" ]]; then
        # Sourced from outside of a frija-command/TAB-completion
        # context; print error message as a "help-message" instead.
        #
        # Furthermore
        #   - Strip any trailing ", aborting." from the help message
        #   - Ignore exit code
        _frija_completion_error_message "${1%, aborting.}"
    else
        #print_message "Frija command"
        print_newline_only_after_dot
        _frija_print_error "${@}"
    fi
}


function print_warning()
{
    warning="${1}"
    message="${2:-}"
    print_separator
    print_message "${BOLD}WARNING:${CLEAR} ${warning}"
    if [[ -n "${message}" ]]; then
        print_message ""
        print_message "${message}"
    fi
    print_separator
}


function print_note()
{
    local message="${1:-}"
    local border="${2:-}"

    declare -i indent="${3:-0}"
    declare -i width="${4:-${WIDTH:-80}}"

    if [[ "${border}" == "y" ]]; then
        print_separator
    fi

    _frija_fold "${message}" "0" "${width}" "Note:"

    if [[ "${border}" == "y" ]]; then
        print_separator
    fi
}


# Create a variable $LINES containing $COLUMNS spaces (or if not set
# use instead terminal width). This variable is then used for creating
# two other variables; $SINGLE_LINE and $DOUBLE_LINE respectively.
COLUMNS=${COLUMNS:-$(tput cols)}
printf -v LINE "%${COLUMNS}s" ' '

# Initialize $SINGLE_LINE by replacing all spaces in $LINE with '-'
# characters
SINGLE_LINE="${LINE// /-}"

# Initialize $DOUBLE_LINE by replacing all spaces in $LINE with '='
# characters
DOUBLE_LINE="${LINE// /=}"


# Number of characters to use before message when splicing a message into a line
declare -i PREFIX_LENGTH=5

function print_separator()
{
    local message="${1:-}"
    local isBold="${2:-}"

    if [[ -z "${message}" ]]; then
        if [[ "${isBold}" == "${BOLD}" ]]; then
            message="${BOLD}${SINGLE_LINE}${CLEAR}"
        else
            message="${SINGLE_LINE}"
        fi
    else
        # Enable extended globbing support in Bash and restore its
        # state to whatever it was when function return. Extended
        # globbing means that you can write globbing expressions like
        # *(foo) that match zero or more occurrences of 'foo'.
        #
        # shellcheck disable=SC2064
        trap "$(_frija_restore_extglob_expression)" RETURN
        shopt -s extglob

        # We have to strip any ANSI escape sequences from the message
        # before we calculate the message length. This is done using
        # Bash builtin regexp string replacement.
        #
        # We are using Bash built in Parameter Expansion replacement
        # function that uses a globbing pattern where $'\e' is
        # expanded to the escape character (0x1b).
        #
        # [\[(] define a character class, i.e. matches one of [ and (
        #
        # *([0-9;]) matches zero or more occurrences of the character
        # class [0-9;]
        #
        # [@-n] finally define a character class that matches all
        # ASCII characters between '@' and 'n' in the ASCII table.
        # Note that all uppercase characters comes before the
        # lowercase characters in the ASCII table.
        local plain="${message//$'\e'[\[(]*([0-9;])[@-n]/}"
        declare -i length="${#plain}"

        # We want a line that looks like this
        # 0         1         2         3
        # 0 2 4 6 8 0 2 4 6 8 0 2 4 6 8 0 2 ...
        # ----- Foobar --------------------...
        #
        # In above example $PREFIX_LENGTH is 5 as there are 5 '-' from
        # the start of the line to the string " Foobar ". Idea is to
        # splice string in two parts and insert the message " Foobar "
        # in such a way that the total length of the line is equal to
        # the length of the line without any message.
        #
        # This is done by first picking $PREFIX_LENGTH characters from
        # $SINGLE_LINE. Then append the message with the ' ' before
        # and after the message. And finally start from the
        # corresponding index in the line and print everything till
        # the end.
        # 0         1         2         3
        # 0 2 4 6 8 0 2 4 6 8 0 2 4 6 8 0 2 ...
        # ----- Foobar --------------------...
        #     *        *
        #     |        |
        #     |        $PREFIX_LENGTH+1+${#message}+1
        #     |
        # $PREFIX_LENGTH
        local prefix="${SINGLE_LINE:0:${PREFIX_LENGTH}}"
        local suffix="${SINGLE_LINE:${PREFIX_LENGTH}+2+${length}}"

        if [[ "${isBold}" == "${BOLD}" ]]; then
            message="${BOLD}${message}${CLEAR}"
        fi

        message="${prefix} ${message} ${suffix}"
    fi

    echo -e "${message}" >&2
}


function print_double_separator()
{
    local message="${1:-}"
    local isBold="${2:-}"

    if [[ -z "${message}" ]]; then
        if [[ "${isBold}" == "${BOLD}" ]]; then
            message="${BOLD}${DOUBLE_LINE}${CLEAR}"
        else
            message="${DOUBLE_LINE}"
        fi
    else
        # We want a line that looks like this
        # 0 2 4 6 8 0 2 4 6 8 0 2 4 6 8 0 2 ...
        # ===== Foobar ====================...
        #
        # In above example $PREFIX_LENGTH is 5 as there are 5 '=' from
        # the start of the line to the string " Foobar ". Idea is to
        # splice string in two parts and insert the message " Foobar "
        # in such a way that the total length of the line is equal to
        # the length of the line without any message.
        #
        # This is done by first picking $PREFIX_LENGTH characters from
        # $DOUBLE_LINE. Then append the message with the ' ' before
        # and after the message. And finally start from the
        # corresponding index in the line and print everything till
        # the end.
        # 0 2 4 6 8 0 2 4 6 8 0 2 4 6 8 0 2 ...
        # ===== Foobar ====================...
        #     *        *
        #     |        |
        #     |        $PREFIX_LENGTH+1${#message}
        #     |
        # $PREFIX_LENGTH
        local prefix="${DOUBLE_LINE:0:${PREFIX_LENGTH}}"
        local suffix="${DOUBLE_LINE:${PREFIX_LENGTH}+2+${#message}}"

        if [[ "${isBold}" == "${BOLD}" ]]; then
            message="${BOLD}${message}${CLEAR}"
        fi

        message="${prefix} ${message} ${suffix}"
    fi

    echo -e "${message}" >&2
}


function print_dot()
{
    if [[ ! -v dotPrinted ]]; then
        # Create a new global variable named 'dotPrinted'. In Bash 4.2
        # there is a bug that causes 'decalre -g' to not create a
        # global variable. Instead use export as a workaround, it
        # should have benign side effects.
        export dotPrinted=""
    fi
    dotPrinted="y"
    echo -n "${BOLD}.${CLEAR}" 1>&2
}


# If wordy mode enabled, always print a newline
#
# If wordy mode is NOT enabled and a dot has been printed, then print
# a newline.
#
# Otherwise do not print any newline.
function print_newline_after_dot()
{
    if [[ "${WORDY:-}" == "y" ]]; then
        print_message
    else
        if [[ -v dotPrinted ]] && [[ -n "${dotPrinted}" ]]; then
            dotPrinted=""
            print_message
        fi
    fi
}


# ONLY print a newline when wordy mode is NOT enabled and a dot has
# been printed.
function print_newline_only_after_dot()
{
    if [[ "${WORDY:-}" != "y" ]]; then
        if [[ -v dotPrinted ]] && [[ -n "${dotPrinted}" ]]; then
            dotPrinted=""
            print_message
        fi
    fi
}


# shellcheck disable=SC2120
function print_debug_enter()
{
    if [[ "${DEBUG:-}" == "y" ]]; then
        print_newline_only_after_dot

        local sourcefile=""
        if (( ${#BASH_SOURCE[@]} > 1 )); then
            sourcefile="${BASH_SOURCE[1]}"
        else
            sourcefile="(Shell environment)"
        fi

        local message="${BOLD}*** ${sourcefile}  "
        message+="${FUNCNAME[2]:-}():${BASH_LINENO[1]}"
        message+="-->${FUNCNAME[1]}():${BASH_LINENO[0]}${CLEAR}  ${*}"

        if [[ -v COMP_TYPE ]]; then
            # Called from within TAB-completion engine; assumed name
            # is name of script file this function is called from
            # appended with '.txt' (extracted from $BASH_SOURCE[1]).
            # If that is not set, for instance when called from
            # completion function default name is
            # 'tab-completion.txt'.

            # Strip everything up to the last '/' in ${BASH_SOURCE[1]}
            local sourcefile="${sourcefile##*/}"

            # Create log-file name
            local logfile="${sourcefile:-tab-completion}.txt"

            # Default behavior is to append to file
            # "/tmp/${USER}/${logfile}"
            logfile="/tmp/${USER}/${logfile}"

            if [[ ! -d "/tmp/${USER}" ]]; then
                if [[ -f "/tmp/${USER}" ]]; then
                    # There already exist a file (not a directory)
                    # called $USER, in this case use $USER as a prefix
                    # for the log-file instead.
                    logfile="/tmp/${USER}_${logfile}"
                else
                    # Ensure log-file folder exist
                    mkdir -p "/tmp/${USER}"
                fi
            fi

            echo "${message}" >> "${logfile}"
        else
            # Ensure formatted text wraps nicely to terminal width and
            # redirect to stderr
            _frija_fold "${message}"

            #fold --spaces --width="${WIDTH:-80}"<<<"${message}" >&2
        fi
    fi
}


# shellcheck disable=SC2120
function print_debug_exit()
{
    if [[ "${DEBUG:-}" == "y" ]]; then
        print_newline_only_after_dot

        local sourcefile=""
        if (( ${#BASH_SOURCE[@]} > 1 )); then
            sourcefile="${BASH_SOURCE[1]}"
        else
            sourcefile="(Shell environment)"
        fi

        local message="${BOLD}*** ${sourcefile}  "
        message+="<--${FUNCNAME[1]}():${BASH_LINENO[0]}${CLEAR}  ${*}"

        if [[ -v COMP_TYPE ]]; then
            # Called from within TAB-completion engine; assumed name
            # is name of script file this function is called from
            # appended with '.txt' (extracted from $BASH_SOURCE[1]).
            # If that is not set, for instance when called from
            # completion function default name is
            # 'tab-completion.txt'.

            # Strip everything up to the last '/' in ${BASH_SOURCE[1]}
            local sourcefile="${sourcefile##*/}"

            # Create log-file name
            local logfile="${sourcefile:-tab-completion}.txt"

            # Default behavior is to append to file
            # "/tmp/${USER}/${logfile}"
            logfile="/tmp/${USER}/${logfile}"

            if [[ ! -d "/tmp/${USER}" ]]; then
                if [[ -f "/tmp/${USER}" ]]; then
                    # There already exist a file (not a directory)
                    # called $USER, in this case use $USER as a prefix
                    # for the log-file instead.
                    logfile="/tmp/${USER}_${logfile}"
                else
                    # Ensure log-file folder exist
                    mkdir -p "/tmp/${USER}"
                fi
            fi

            echo "${message}" >> "${logfile}"
        else
            # Ensure formatted text wraps nicely to terminal width and
            # redirect to stderr
            _frija_fold "${message}"

            #fold --spaces --width="${WIDTH:-80}"<<<"${message}" >&2
        fi
    fi
}


function print_debug()
{
    if [[ "${DEBUG:-}" == "y" ]]; then
        print_newline_only_after_dot

        local sourcefile=""
        if (( ${#BASH_SOURCE[@]} > 1 )); then
            sourcefile="${BASH_SOURCE[1]}"
        else
            sourcefile="(Shell environment)"
        fi

        local message="${BOLD}*** ${sourcefile}  "
        message+="${FUNCNAME[1]}():${BASH_LINENO[0]}${CLEAR}  ${*}"

        if [[ -v COMP_TYPE ]]; then
            # Called from within TAB-completion engine; assumed name
            # is name of script file this function is called from
            # appended with '.txt' (extracted from $BASH_SOURCE[1]).
            # If that is not set, for instance when called from
            # completion function default name is
            # 'tab-completion.txt'.

            # Strip everything up to the last '/' in ${BASH_SOURCE[1]}
            local sourcefile="${sourcefile##*/}"

            # Create log-file name
            local logfile="${sourcefile:-tab-completion}.txt"

            # Default behavior is to append to file
            # "/tmp/${USER}/${logfile}"
            logfile="/tmp/${USER}/${logfile}"

            if [[ ! -d "/tmp/${USER}" ]]; then
                if [[ -f "/tmp/${USER}" ]]; then
                    # There already exist a file (not a directory)
                    # called $USER, in this case use $USER as a prefix
                    # for the log-file instead.
                    logfile="/tmp/${USER}_${logfile}"
                else
                    # Ensure log-file folder exist
                    mkdir -p "/tmp/${USER}"
                fi
            fi

            echo "${message}" >> "${logfile}"
        else
            # Ensure formatted text wraps nicely to terminal width and
            # redirect to stderr
            _frija_fold "${message}"

            #fold --spaces --width="${WIDTH:-80}"<<<"${message}" >&2
        fi
    fi
}


function print_debug_array()
{
    local arrayName="${1}"
    local prefix="${2:-}"

    if [[ "${DEBUG:-}" == "y" ]]; then
        print_newline_only_after_dot

        local sourcefile=""
        if (( ${#BASH_SOURCE[@]} > 1 )); then
            sourcefile="${BASH_SOURCE[1]}"
        else
            sourcefile="(Shell environment)"
        fi

        local message="${BOLD}*** ${sourcefile}  "
        message+="${FUNCNAME[1]}():${BASH_LINENO[0]}${CLEAR}  "
        if [[ -n "${prefix}" ]]; then
            message+="${prefix}: "
        fi

        local arrayData=""
        arrayData=$(declare -p "${arrayName}")
        message+="${arrayData}"

        if [[ -v COMP_TYPE ]]; then
            # Called from within TAB-completion engine; assumed name
            # is name of script file this function is called from
            # appended with '.txt' (extracted from $BASH_SOURCE[1]).
            # If that is not set, for instance when called from
            # completion function default name is
            # 'tab-completion.txt'.

            # Strip everything up to the last '/' in ${BASH_SOURCE[1]}
            local sourcefile="${sourcefile##*/}"

            # Create log-file name
            local logfile="${sourcefile:-tab-completion}.txt"

            # Default behavior is to append to file
            # "/tmp/${USER}/${logfile}"
            logfile="/tmp/${USER}/${logfile}"

            if [[ ! -d "/tmp/${USER}" ]]; then
                if [[ -f "/tmp/${USER}" ]]; then
                    # There already exist a file (not a directory)
                    # called $USER, in this case use $USER as a prefix
                    # for the log-file instead.
                    logfile="/tmp/${USER}_${logfile}"
                else
                    # Ensure log-file folder exist
                    mkdir -p "/tmp/${USER}"
                fi
            fi

            echo "${message}" >> "${logfile}"
        else
            # Ensure formatted text wraps nicely to terminal width and
            # redirect to stderr
            _frija_fold "${message}"

            #fold --spaces --width="${WIDTH:-80}"<<<"${message}" >&2
        fi
    fi
}


function print_debug_indirect_array()
{
    local arrayName="${1}"
    local prefix="${2:-}"

    if [[ "${DEBUG:-}" == "y" ]]; then
        print_newline_only_after_dot

        local sourcefile=""
        if (( ${#BASH_SOURCE[@]} > 1 )); then
            sourcefile="${BASH_SOURCE[1]}"
        else
            sourcefile="(Shell environment)"
        fi

        local message="${BOLD}*** ${sourcefile}  "
        message+="${FUNCNAME[1]}():${BASH_LINENO[0]}${CLEAR}  "
        if [[ -n "${prefix}" ]]; then
            message+="${prefix}: "
        fi

        local arrayRef="${arrayName}[@]"
        local item=""
        for item in "${!arrayRef}"; do
            message+="${item}='${!item}'  "
        done

        if [[ -v COMP_TYPE ]]; then
            # Called from within TAB-completion engine; assumed name
            # is name of script file this function is called from
            # appended with '.txt' (extracted from $BASH_SOURCE[1]).
            # If that is not set, for instance when called from
            # completion function default name is
            # 'tab-completion.txt'.

            # Strip everything up to the last '/' in ${BASH_SOURCE[1]}
            local sourcefile="${sourcefile##*/}"

            # Create log-file name
            local logfile="${sourcefile:-tab-completion}.txt"

            # Default behavior is to append to file
            # "/tmp/${USER}/${logfile}"
            logfile="/tmp/${USER}/${logfile}"

            if [[ ! -d "/tmp/${USER}" ]]; then
                if [[ -f "/tmp/${USER}" ]]; then
                    # There already exist a file (not a directory)
                    # called $USER, in this case use $USER as a prefix
                    # for the log-file instead.
                    logfile="/tmp/${USER}_${logfile}"
                else
                    # Ensure log-file folder exist
                    mkdir -p "/tmp/${USER}"
                fi
            fi

            echo "${message}" >> "${logfile}"
        else
            # Ensure formatted text wraps nicely to terminal width and
            # redirect to stderr
            _frija_fold "${message}"

            #fold --spaces --width="${WIDTH:-80}"<<<"${message}" >&2
        fi
    fi
}
