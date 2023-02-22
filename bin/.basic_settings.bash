# More safety, by turning some bugs into errors. Without 'errexit' you
# don't need ! and can replace PIPESTATUS with a simple $?, but then
# we would need to remember to explcitly test return status for each
# command. Note that ! hides the exit status of the executed command.
# Due to this we have to use PIPESTATUS to get to it and no history
# expansion when using '!' in for instance echo strings.
set -o errexit -o pipefail -o noclobber -o nounset +o history

# Enable extended globbing that support regular expression-like syntax
shopt -s extglob
# Disable error message if globbing fails
shopt -u failglob
# Enable empty string no match response instead of glob pattern being returned
shopt -s nullglob
