#!/env/ruby
require 'erb'

message_file = ARGV[0]
commit_source = ARGV[1]
# sha1 = ARGV[2]

exit if ['merge', 'commit', 'message'].include? commit_source

working_dir = File.expand_path(File.join(File.dirname(message_file), '..'))
template_file = File.join(working_dir, '.git_tools', 'templates', 'prepare_commit_msg')
contents = File.read(message_file)

has_merge_message = contents.match(/^Merge branch/m) # Commit with resolved merge conflicts don't have a commit source.
exit if has_merge_message
ticket_no_from_branch_name = contents.scan(/On branch .+#(\d{1,5})/)

if ticket_no_from_branch_name.empty?
  references = nil
  default_line = <<-MESSAGE
#
# PLEASE ADD THE ISSUE TRACKER NUMBER TO THE BRANCH NAME.
# Replace these lines with any applicable issue tracker references.
MESSAGE
else
  references = ticket_no_from_branch_name.join(', #')
  default_line = "Issue tracker: ##{references}"
end

if File.exists?(template_file)
  message_template = ERB.new(File.read(template_file), 0, '>').result
else
  message_template = <<-MESSAGE

# [Tell us *why* are you committing on the line above.]

# [Details below this line.]
#{default_line}
#
# Check out the following links on how to write proper git messges:
#
# http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
# http://robots.thoughtbot.com/post/48933156625/5-useful-tips-for-a-better-commit-message
#
MESSAGE
end

File.open(message_file, 'w') do |file|
  file.write(message_template.chomp)
  file.write(contents)
end
