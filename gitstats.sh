#!/bin/bash
# Returns all Git projects on a system with information about them

#TODO STATS
# Average Commit Size       
# Most common committer
# First commit date
# Programming Languages used/detected

# Find all Git projects on a system
function getGit {
    find . -name .git -type d -prune
    # find /home -name .git -type d -prune
}

# Read all .git project files on system into array variable
mapfile -t gitfiles < <( getGit )

# Number of projects found
echo "Number of git repos found: ${#gitfiles[@]}"

for x in "${gitfiles[@]}";
do
    # Returns size of local repository
    x="$(dirname ${x})"
    du -sh $x

    # Most common committers
    # Get all commits with PCRE grep and put them in an array (easier way to do this?)
    mapfile gitcommits < <( git log | grep -Pz 'commit.*(?!commit)')
done


# git log --stat


