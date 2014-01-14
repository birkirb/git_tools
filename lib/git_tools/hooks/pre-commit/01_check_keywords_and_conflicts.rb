#!/env/ruby

FAILURE = false

diff_lines = `git diff`.split("\n")
added_lines = diff_lines.select { |line| line =~ /^\+/ }

conflict_markers = ['<<<<<<<', '=======', '>>>>>>>']
debug_keywords = ['puts', 'debugger']

conflict_lines = added_lines.select do |line|
  conflict_markers.any? { |marker| line =~ /#{marker}/ }
end
debug_lines = added_lines.select do |line|
  debug_keywords.any? { |keyword| line =~ /\b#{keyword}\b/ }
end

$stdin.readlines.each { |l| puts l }

if conflict_lines.any?
  puts "You might be committing changes containing conflict markers, this indicates an unfinished merge"
  puts "The lines are the following:"
  conflict_lines.each { |line| puts line }
end
if debug_lines.any?
  puts "You might be committing changes containing debug keywords"
  puts "The lines are the following:"
  debug_lines.each { |line| puts line }
end
if conflict_lines.any? || debug_lines.any?
  puts "If you are sure you want to make this commit, commit again with the --no-verify flag"
  exit(FAILURE)
end
