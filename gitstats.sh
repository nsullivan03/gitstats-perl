#!/bin/bash
# Returns all Git projects on a system with information about them

#TODO STATS
# Average Commit Size       
# First commit date
# Programming Languages used/detected (use github-linguist)
# Options/Shell Parameters

#FIXME Bugs
# Arguments too long for xargs
# Check program versions to ensure compatibility (Perl, Ruby, etc.)
# No such file or directory error from du into cd having too many arguments

# Absolute file path to our directory
BASEDIR="$(dirname $(realpath -s $0))" #  Credit: https://stackoverflow.com/questions/4774054/reliable-ay-for-a-bash-script-to-get-the-full-path-to-itself

# Find all Git projects on a system
function getGit {
    # find ../ -name .git -type d -prune
    find /home -name .git -type d -prune
}

# Close all processes when SIGINT is received
function handleSigInt {
    echo "SIGINT received. Program exiting..."
    pkill -P $$
    exit 0
}


trap handleSigInt SIGINT

# Read all .git project files on system into array variable
mapfile -t gitfiles < <( getGit )

# Number of projects found
echo "Number of git repos found: ${#gitfiles[@]}"

for x in "${gitfiles[@]}";
do
    # Returns size of local repository
    x="$(dirname ${x})"
    echo ""
    du -shP "$x" &
    wait $! # Waits until last command finishes
    

    # Most frequent committers
    # Will require perl script to create a hash variable
    # Create a subshell in the next directory, grep all commits from the git log, and pass them to the perl script for processing
    (cd $x && git log | grep -Pz 'commit.*(?!commit)' | xargs -0 perl $BASEDIR/commits.pl)
    

done

exit 0
