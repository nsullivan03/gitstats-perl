#!/usr/bin/env perl
use Modern::Perl;
#use Capture::Tiny ':all';

# Captures all commits and outputs data about them

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

my %authors;

my @author = $ARGV[0] =~ /Author:(.*)/g;

# Stores authors in hash as keys with values equal to their commit totals
for my $i (@author)
{
    if (exists $authors{$i})
    {
        $authors{$i} += 1;
    }
    else
    {
        $authors{$i} = 0;
    }
}

print ("Most frequent committers\n");

for (my $i = 0; $i < 3; $i++)
{
    my $maxauthor = findMaxKey(\%authors);

    
    if ($maxauthor)
    {
        print("$maxauthor ($authors{$maxauthor} times)\n");
        delete $authors{$maxauthor};
    }
  
} 



exit;