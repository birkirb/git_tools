require 'git_tools/extensions/time'

module GitTools
  module Branches

    KEEP_LIST = %w(master stable testing)
    KEEP_BRANCH_FILENAME = '.git_keep_branches'

    def self.git_keep_branches_from_file
      if File.exists?(KEEP_BRANCH_FILENAME)
        File.readlines(KEEP_BRANCH_FILENAME).each { |line| line.strip! }
      else
        []
      end
    end

    def self.default_keep_list
      KEEP_LIST + git_keep_branches_from_file
    end

    class Cleaner
      MASTER_BRANCH = 'master'
      DEFAULT_REMOTE = 'origin'
      AGE_THRESHOLD_IN_MONTHS_FOR_DELETING_REMOTE_BRANCHES_IN_MASTER = 1 * Time::SECONDS_IN_MONTH
      AGE_THRESHOLD_IN_MONTHS_FOR_DELETING_ANY_UNMERGED_BRANCHES = 6 * Time::SECONDS_IN_MONTH

      attr_reader :master_branch, :remote, :protected_branches

      def self.with_local(master_branch, protected_branches = nil)
        self.new(nil, master_branch, protected_branches)
      end

      def self.with_origin(protected_branches = nil)
        self.new(DEFAULT_REMOTE, nil, protected_branches)
      end

      public

      def initialize(remote = nil, master_branch = nil, protected_branches = nil)
        @remote = remote
        @protected_branches = protected_branches || Branches.default_keep_list
        @master_branch = master_branch || get_remote_head || MASTER_BRANCH
        @branches = branches

        if @master_branch.nil?
          raise "Master branch was not set or determined."
        else
          puts "Master branch is #{@master_branch}" if $VERBOSE
        end
      end

      def local?
        @remote.nil?
      end

      def run!
        (@branches - protected_branches - [master_branch] ).each do |branch|
          branch = Branch.new(branch, remote)
          containing_branches = contained_branches(branch.normalized_name) - [branch.name]

          if protected_branch?(branch.name)
            puts "#{label_for_remote} branch [#{branch}] is on keep list ( #{kbs.join(" , ")} )" if $VERBOSE
          elsif in_master_branch?(containing_branches)
            if delete_branch_merged_to_master_without_confirmation?(branch.age)
              message = "Removing #{label_for_remote.downcase} branch [#{branch}] since it is in #{master_branch}. [#{branch.age.relative}]"
              branch.remove!(message)
            else
              message = "#{label_for_remote} branch [#{branch}] is in #{master_branch} and could be deleted [#{branch.age.relative}]"
              branch.confirm_remove(message, "Delete #{branch}?")
            end
          elsif delete_unmerged_branch?(branch.age)
            branch_list = containing_branches.empty? ? '' : "Branch has been merged into:\n  #{containing_branches.join("\n  ")}"
            message = "#{label_for_remote} branch [#{branch}] is not on #{master_branch}, but old [#{branch.age.relative}]. #{branch_list}"
            branch.confirm_remove(message, "Delete old unmerged branch: #{branch} ?")
          else
            puts "Ignoring unmerged #{label_for_remote.downcase} branch [#{branch}]" if $VERBOSE
          end

          if defined?($signal_handler)
            break if $signal_handler.interrupted?
          end
        end

        git_remote_prune
      end

      private

      def git_remote_prune
        `git remote prune #{remote}` unless local?
      end

      def label_for_remote
        local? ? "Local" : "Remote"
      end

      def branches
        clean_branches_result(`git branch #{git_argument_for_remote}`)
      end

      def git_argument_for_remote
        local? ? '' : ' -r'
      end

      def get_remote_head
        (`git branch -r | grep #{remote}/HEAD`).sub(/#{remote}\/HEAD -> #{remote}\//, '').strip
      end

      def clean_branches_result(branches)
        bs = branches.to_s.split(/\n/).map { |b| b.strip.sub(/^\s*\*\s*/, '') }

        if local?
          bs
        else
          # technically split out remote branch name (may not be origin) and return as list
          bs.delete_if { |b| b =~ /HEAD/ }
          bs.find_all { |b| /^#{remote}\// =~ b }.map { |b| b.sub(/^#{remote}\//, '') }
        end
      end

      def contained_branches(branch)
        # git's --contains param seems to cause this stderr out:
        #   error: branch 'origin/HEAD' does not point at a commit
        # piping that to stderr and cleaning out.
        clean_branches_result(`git branch #{git_argument_for_remote} --contains #{branch} 2>&1`)
      end

      def in_master_branch?(branch)
        branch.include?(master_branch)
      end

      def protected_branch?(branch)
        protected_branches.include?(branch)
      end

      def delete_branch_merged_to_master_without_confirmation?(time)
        if local?
          true
        else
          (Time.now - time) > AGE_THRESHOLD_IN_MONTHS_FOR_DELETING_REMOTE_BRANCHES_IN_MASTER
        end
      end

      def delete_unmerged_branch?(time)
        (Time.now - time) > AGE_THRESHOLD_IN_MONTHS_FOR_DELETING_ANY_UNMERGED_BRANCHES
      end

    end

    class Branch

      DATE_REGEXP = /^Date:\s+(.*)$/

      def self.age(branch)
        time = DATE_REGEXP.match(`git log --shortstat --date=iso -n 1 #{branch}`)
        Time.parse(time[1])
      end

      def self.executor
        ActionExecutor.new
      end

      public

      attr_reader :name, :remote, :age

      def initialize(name, remote)
        @name = name
        @remote = remote
        @age = self.class.age(normalized_name)
      end

      def normalized_name
        local? ? name : "#{remote}/#{name}"
      end

      def remove!(message)
        self.class.executor.execute(remove_branch_action, message)
      end

      def confirm_remove(message, prompt)
        self.class.executor.execute(remove_branch_action, message, prompt)
      end

      def to_s
        name
      end

      private

      def local?
        remote.nil?
      end

      def remove_branch_action
        local? ? "git branch -d #{name}" : "git push #{remote} :#{name}"
      end
    end

    class ActionExecutor

      @@test_mode = true
      @@skip_prompted = false

      def self.test_mode=(value)
        @@test_mode = (value == true)
      end

      def self.skip_prompted=(value)
        @@skip_prompted = (value == true)
      end

      def execute(command, action_message, confirmation_prompt = nil)
        if @@test_mode
          $stderr.puts("#{action_message} -> #{command}")
        else
          if confirmation_prompt
            if @@skip_prompted
              puts "#{action_message} -> skipping prompts" if $VERBOSE
            else
              puts action_message
              puts "#{confirmation_prompt} [y/N]"
              case $stdin.gets.chomp
              when 'y'
                `#{command}`
              end
            end
          else
              puts action_message
            `#{command}`
          end
        end
      end
    end

  end
end