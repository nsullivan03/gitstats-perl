#!/usr/bin/env perl
use Modern::Perl;
use Cwd 'abs_path';
# use Test::More;
use Capture::Tiny ':all';

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

my $basedir = abs_path();

# Find all git projects on a system and store them in a buffer.
my @gitprojects = `find /home -name .git -type d -prune`;

say "Number of git repos found: $#gitprojects";

foreach (@gitprojects)
{
    # Get absolute path of git repo and remove the git file from the path
    my $x = abs_path("$_");
    $x = substr ($x, 0, length($x) - 6);

    # Run disk usage command to get repository size
    system("bash", "-c", "du -shP \"$x\"");
    say "$x";

    chdir("$x") or die "Failed to change directory to $x!";

    # Grab commits
    my $rawcommits = capture_stdout {
        system("git log");
    };

    # Get commits from raw output and put them into an array
    $/ = "";
    my @commits = ($rawcommits =~ /commit.*\n.*\n.*\n(?!commit)/g);
    $/ = "\n";
    # foreach (@commits) {
    #     print "$_";
    # };
    # print "$commits[0]";
    # print "$#commits";


    my %authors;

    
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
            

        }

    }
    

    # # TODO Can I rewrite this so it doesnt use a C-style for loop?
    # # Match for author field and place in new array variable
    # my (@author, %authors);
    # for (my $i = 0; $i < $#commits; $i++) {
    #     # print "$commits[$i]";
    #     $author[$i] = $commits[$i] =~ /Author:(.*)\n/g;
    #     # print "$commits[$i]";
    # }; 

    # # Stores authors in hash as keys with values equal to their commit totals
    # for my $i (@author)
    # {
    #     # print "$author[$i]";
    #     if (exists $authors{$i})
    #     {
    #         $authors{$i} += 1;
    #     }
    #     else
    #     {
    #         $authors{$i} = 0;
    #     }
    # }
    
    # print ("Most frequent committers\n");

    for (my $i = 0; $i < 3; $i++)
    {
        my $maxauthor = findMaxKey(\%authors);

        
        if ($maxauthor)
        {
            printf ("%d: $maxauthor ($authors{$maxauthor} times)\n", $i + 1);
            delete $authors{$maxauthor};
        }
    
    } 
}


exit;