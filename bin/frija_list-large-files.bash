#!/bin/bash

# When run within a repo it lists the 10 largest files at the top of
# the output. Each file is listed again together with the commit that
# introduced the file as well as any commits that modified the file or
# renamed it.

git rev-list --objects --all | \
    git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
    sed -n 's/^blob //p' | \
    sort --numeric-sort --key=2 | \
    cut -c 1-12,41- | \
    tail -n 10 | while read -r a b c; do { $(command -v gnumfmt || echo numfmt) --field=2 --to=iec-i --suffix=B --padding=7 --round=nearest <<< "${a} ${b} ${c}"; }; done

echo ""
echo ""

git rev-list --objects --all | \
    git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
    sed -n 's/^blob //p' | \
    sort --numeric-sort --key=2 | \
    cut -c 1-12,41- | \
    tail -n 10 | while read -r a b c; do { $(command -v gnumfmt || echo numfmt) --field=2 --to=iec-i --suffix=B --padding=7 --round=nearest <<< "${a} ${b} ${c}"; git --no-pager log --follow --find-renames=40% -- "${c}"; echo "================================"; echo ""; }; done
