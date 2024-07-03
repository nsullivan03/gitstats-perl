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

    system("bash", "-c", "du -shP \"$x\"");
    # say "$x";

    chdir("\"$x\"");

    my @commits = capture_stdout {
        system("git log");
    }
    
}


exit;