# Analyze programming languages used with github-linguist
require 'rugged'
require 'linguist'

# Take in a single project and its head (ARGV for evaluating commandline arguments)
# Calculate language out for the repository
# Return to Perl script and continue

# puts (ARGV[0])

# Trap for SIGINT
Signal.trap(2, proc { puts "Terminating: #{$$}" })

repo = Rugged::Repository.new(ARGV[0])
project = Linguist::Repository.new(repo, repo.head.target_id)
puts project.language
puts project.languages

exit