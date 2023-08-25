# Name of Fensalir repo. Variable is assigned a hard coded value
# during installation.
#
# shellcheck disable=SC2034
_FENSALIR_REPONAME="${_REPO_NAME}"

# Create a path to the bin folder of the Fensalir repo from path to
# this script. Variable is assigned a hard coded value during
# installation
#
# shellcheck disable=SC2034
_FENSALIR_ROOT="${_REPO_PATH}"


# Define where we are located. These settings affect things like tag
# names created using 'frija tag' command. It can also affects which
# commit you see in Fensalir-, locale-, and subsystem-repos when
# selecting release or development branches in those repos using the
# corresponding frija commands.
#
# These variables are assigned hard coded values during installation.
export _FRIJA_DEVELOPMENT_COUNTRY=''
export _FRIJA_DEVELOPMENT_SITE=''
export _FRIJA_DEVELOPMENT_DOMAIN=''


# Define 'safe' variants of where we are located. The corresponding
# variables are transformed to safe variants that may be used in
# filenames, search paths, branch names, and so on.
#
# These variables are assigned hard coded values during installation.
export _FRIJA_DEVELOPMENT_SAFE_COUNTRY=''
export _FRIJA_DEVELOPMENT_SAFE_SITE=''
export _FRIJA_DEVELOPMENT_SAFE_DOMAIN=''


# Continue configuration of Frija in another script. By splitting this
# in two separate files it simplifies updates of Fensalir repo when
# the actual configuration script is modified.
#
# shellcheck source=../config/fensalir-config.bash
source "${_FENSALIR_ROOT}/config/fensalir-config.bash"
