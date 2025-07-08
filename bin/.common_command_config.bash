################################################################################
#  NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
################################################################################
# This file must not be sourced via command completion as it would
# otherwise poison the Bash environment with Fensalir/Frija-internal
# variables.
################################################################################
#  NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
################################################################################

# Name of SECI-file that must be defined in build environment repo
# used by the workspace. This SECI-file must define relevant
# environment variables for the expected GNU Make version, e.g. GNU
# Make 4.4.1.
MAKE_SECI_NAME_SANS_OS_AND_EXTENSION="gnumake-4.4.1"
