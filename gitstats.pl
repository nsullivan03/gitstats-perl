#!/usr/bin/env perl
use Modern::Perl;
use Cwd 'abs_path';
# use Test::More;
use Capture::Tiny ':all';
use Date::Parse;

#TODO
# Average Commit Size (how to accomplish this?)
# Programming Languages used/detected (use github-linguist)

# Find the key with the highest value in a hash
sub findMaxKey {
    my $max = 0;
    my $maxkey;

    my %hash = %{$_[0]};
    foreach my $i (keys %hash)
    {
        if ($hash{$i} > $max)
        {
            $max = $hash{$i};
            $maxkey = $i;
        }
    }

    return $maxkey;

}

# Get the most recent date
sub findFirstDate {
    my ($firstut, $firstd);

    my %hash = %{$_[0]};
    foreach my $i (keys %hash)
    {
        my $itime = str2time($i);

        if (!defined $firstut)
        {
            $firstut = $itime;
            $firstd = $i;
        }
        elsif ($itime < $firstut)
        {
            $firstut = $itime;
            $firstd = $i;
        }
    }

    return $firstd;
}

my $basedir = abs_path();

# Find all git projects on a system and store them in a buffer.
my @gitprojects = `find /home -name .git -type d -prune`;

say "Number of git repos found: $#gitprojects";

foreach (@gitprojects)
{
    # # Debug path for git project
    # my $gitpath = "$_";
    
    # Get absolute path of git repo and remove the git file from the path
    my $x = abs_path("$_");
    $x = substr ($x, 0, length($x) - 6);

    # Run disk usage command to get repository size
    system("bash", "-c", "du -shP \"$x\"");
    #FIXME Adding die clause causes this line to always fail?
    # system("bash", "-c", "du -shP \"$x\"") or die "Failed to calculate disk usage for $x";
    say "$x";

    chdir("$x") or die "Failed to change directory to $x!";

    # Grab commits
    my $rawcommits = capture_stdout {
        system("git log");
    };

    # Get commits from raw output and put them into an array
    $/ = "";
    #TODO See if there is a way to better implement this?
    my @commits = ($rawcommits =~ /commit.*\n.*\n.*\n(?!commit)/g);
    $/ = "\n";
    # foreach (@commits) {
    #     print "$_";
    # };
    # print "$commits[0]";
    # print "$#commits";


    my (%authors, %dates);

    
    foreach (@commits)
    {

        # Split commits into fields
        my @fields = split /\n/, $_;

        
        # print "$#fields\n";
        # print "$_";
        # for (my $i = 0; $i < $#fields + 1; $i++)
        # {
        #     print "$i.) $fields[$i]\n";
        # }

        for (my $i = 0; $i < $#fields + 1; $i++)
        {
            # match for author field
            if ($fields[$i] =~ /^Author:(.*)$/g)
            {
                # $^N matches the last captured parentheses 
                my $authormatch = $^N;
                # printf "\$^N: %s\n", $^N;
                # print "$authormatch\n";

                # add author to author count hash
                if ($authormatch)
                {
                    if (exists $authors{$authormatch})
                    {
                        $authors{$authormatch} += 1;
                    }
                    else {
                        $authors{$authormatch} = 0;
                    }
                }
            }

            # match for Date field
            elsif ($fields[$i] =~ /^Date:\s*(.*)$/g)
            {
                my $date = $^N;

                if ($date)
                {
                    if (exists $dates{$date})
                    {
                        $dates{$date} += 1;
                    }
                    else {
                        $dates{$date} = 0;
                    }
                }


            }
            

        }

    }

    # print three users with the most commits to the repo
    for (my $i = 0; $i < 3; $i++)
    {
        my $maxauthor = findMaxKey(\%authors);

        
        if ($maxauthor)
        {
            printf ("%d: $maxauthor ($authors{$maxauthor} times)\n", $i + 1);
            delete $authors{$maxauthor};
        }
    
    }

    # Print the date of the first commit
    my $firstcommit = findFirstDate(\%dates);
    printf("First commit date: %s\n", $firstcommit);

    # Pass repository to ruby script for language analysis
    chomp;
    my @linguistcommand = ("ruby", "$basedir/langanalyst.rb", "$_");

    #printf("%s and %s\n", $linguistcommand[1], $_);
    system(@linguistcommand) != -1 or die "github-linguist failed: $?";

}


exit;