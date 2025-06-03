#!/usr/bin/env perl
use Modern::Perl;
use Cwd 'abs_path';
use Getopt::Std;
use Capture::Tiny ':all';
use Date::Parse;
use warnings;
use strict;
use File::Find;
# use App::find2perl;

#TODO
# Average Commit Size (how to accomplish this?)
# Warning prompts (?)


# Interrupt signal handler
sub catch_int {
    die ("Received Interrupt signal.");
}

# Catch interrupt signal (Ctrl-C)
$SIG{INT} = \&catch_int;


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
my $path = "/home";
my $langflag = 0;


# Process command line arguments
my %opts;
getopts('hf:lo:', \%opts);

foreach (keys %opts)
{
    if ($_ eq 'h') { 
        say("gitstats - output information about all github repositories under a directory");
        print("\n");
        say("-h - prints this help message");
        say("-f DIRECTORY - use filepath as directory to scan (default is /home)");
        say("-l - use github-linguist to analyze programming languages used");
        say("-o DIRECTORY - output information to logfile at directory (default is current directory)");
        exit; 
    }; # help
    if ($_ eq 'f') { 
        if (!defined $_)
        {
            die("No file path given for flag -f");
        }
        
        $path = $opts{$_};

        # Check for filepath correctness
        opendir(my $dir, $path) or die("Invalid file path given for flag -f");
        closedir($dir);
    };
    if ($_ eq 'l') { $langflag = 1; }; # Language analysis
    if ($_ eq 'o') {
        # if no filepath is given, use base directory
        my $outpath = "";
        if (!defined $_)
        {
            $outpath = "$basedir";
        }
        else
        {
            $outpath = $opts{$_};
        }

        # Remove trailing slash and create timestamp
        $/ = "/";
        chomp($outpath);
        $/ = "\n";
        my @time = localtime(time);
        my $timestamp = "$time[5]-$time[4]-$time[3]_$time[2]-$time[1]-$time[0]"; # Shouldnt need to worry about file overwriting, as timestamp is to the second
        
        # Open filehandle and set it to default output. Print path so we know what directory was searched in the log.
        open(my $outlog, ">", "$outpath/gitstats-$timestamp.output") or die("unable to open output file for -o");
        select($outlog);
        say "$path";
        
    }   
}

# Find all git projects on a system and store them in a buffer.
my @gitprojects = `find $path -name .git -type d -prune`;

say "Number of git repos found: " . ($#gitprojects + 1) . "\n"; 

foreach (@gitprojects)
{
    
    # Get absolute path of git repo and remove the git file from the path
    my $x = abs_path("$_");
    $x = substr ($x, 0, length($x) - 6);

    # Run disk usage command to get repository size
    system("bash", "-c", "du -shP \"$x\"") == 0 or die "Failed to calculate disk usage for $x";
    say "$x";

    chdir("$x") or die "Failed to change directory to $x!";

    # Grab commits
    my $rawcommits = capture_stdout {
        system("git log");
    };

    # Get commits from raw output and put them into an array
    $/ = "";
    #TODO Check this regexp for bugs
    # my @commits = ($rawcommits =~ /commit.*\n.*\n.*\n(?!commit)/g);
    my @commits = ($rawcommits =~ /(commit(.*\n(?!commit))+)/g);
    $/ = "\n";


    my (%authors, %dates);

    
    foreach (@commits)
    {

        # Split commits into fields
        my @fields = split /\n/, $_;

        for (my $i = 0; $i < $#fields + 1; $i++)
        {
            # match for author field
            if ($fields[$i] =~ /^Author:(.*)$/g)
            {
                # $^N matches the last captured parentheses 
                my $authormatch = $^N;

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

    
    if ($langflag)
    {
        # Pass repository to ruby script for language analysis
        chomp;
        my @linguistcommand = ("ruby", "$basedir/langanalyst.rb", "$_");

        system(@linguistcommand) == 0 or die "github-linguist failed: $?";
    }
    

    printf("\n");
}


exit;