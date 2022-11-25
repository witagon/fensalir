@ECHO OFF

IF NOT "%1" == "" GOTO argsExist
@ECHO "ERROR: No arguments given, NOTHING DONE!"
exit 1


:argsExist
IF NOT "%USERNAME%" == "" GOTO usernameExist
@ECHO "ERROR: Variable USERNAME not set or empty, NOTHING DONE!"
exit 1


:usernameExist
IF NOT "%TMP%" == "" GOTO tmpExist
@ECHO "ERROR: Variable TMP not set or empty, NOTHING DONE!"
exit 1

:tmpExist
IF NOT "%TMP%" == "" GOTO tempExist
@ECHO "ERROR: Variable TEMP not set or empty, NOTHING DONE!"
exit 1

:tempExist
@ECHO Expanding indirect references in TMP and TEMP
CALL SET TMP=%%TMP:!USERNAME!=%USERNAME%%%
CALL SET TEMP=%%TEMP:!USERNAME!=%USERNAME%%%
@ECHO TMP=%TMP%
@ECHO TEMP=%TEMP%
@ECHO.

REM Create environment variables not possible to create in Bash due to
REM that the names contain parentheses.
@ECHO Setting "problematic" environment variables (not possible to do in Bash)
SET CommonProgramFiles(x86)=%CommonProgramFiles_x86_%
SET ProgramFiles(x86)=%ProgramFiles_x86_%
@ECHO CommonProgramFiles(x86)=%CommonProgramFiles(x86)%
@ECHO ProgramFiles(x86)=%ProgramFiles(x86)%
@ECHO.

REM Call the command given (on the command line) with its arguments
@ECHO Calling "%*"
%*
