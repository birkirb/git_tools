module GitTools
  module Hooks
    GIT_HOOK_INSTALL_LINE_BEGIN = "# BEGIN Ruby git-hooks\n"
    GIT_HOOK_INSTALL_LINE_END = "# END Ruby git-hooks\n"
    GIT_HOOK_DIR = File.join('.git', 'hooks')
    GIT_TOOLS_CUSTOM_HOOKS_DIR = File.join(CUSTOM_DIR, 'hooks')
    GIT_TOOLS_INCLUDED_HOOKS_DIR = File.join(File.dirname(__FILE__), 'hooks')

    def self.with_git_hook_files
      if File.exist?(GIT_HOOK_DIR)
        default_ruby_hooks.merge(custom_ruby_hooks).each do |dir, files|
          files.each do |file|
            git_hook = File.join(GIT_HOOK_DIR, file)
            yield(dir, file, git_hook)
          end
        end
      else
        puts "Git hook directory not found."
      end
    end

    def self.default_ruby_hooks
      {GIT_TOOLS_INCLUDED_HOOKS_DIR => (Dir.entries(GIT_TOOLS_INCLUDED_HOOKS_DIR) - ['.', '..'])}
    end

    def self.custom_ruby_hooks
      if Dir.exists?(GIT_TOOLS_CUSTOM_HOOKS_DIR)
        {GIT_TOOLS_CUSTOM_HOOKS_DIR => (Dir.entries(GIT_TOOLS_CUSTOM_HOOKS_DIR) - ['.', '..'])}
      else
        {}
      end
    end

    def self.clear_git_hooks
      with_git_hook_files do |dir, ruby_hook, git_hook|
        if File.exists?(git_hook)
          hook_content = File.read(git_hook)
          if hook_content.match(/#{GIT_HOOK_INSTALL_LINE_BEGIN}/)
            puts "Clearing Ruby #{ruby_hook} git-hooks."
            hook_content.gsub!(/#{GIT_HOOK_INSTALL_LINE_BEGIN}.*#{GIT_HOOK_INSTALL_LINE_END}/m, '')
            File.open(git_hook, 'w+') do |file|
              file.write(hook_content)
            end
          end
        end
      end
    end

    def self.install_git_hooks
      with_git_hook_files do |ruby_hook_dir, ruby_hook_file, git_hook|
        if File.exists?(git_hook)
          hook_content = File.read(git_hook)
        else
          hook_content = "#!/bin/sh\n\n"
        end

        if hook_content.match(/#{GIT_HOOK_INSTALL_LINE_BEGIN}/)
          next
        else
          puts "Installing Ruby #{ruby_hook_file} git-hooks."
          hook_commands = ''
          hook_files = File.join(ruby_hook_dir, ruby_hook_file)
          puts "Hook file: #{hook_files}" if $VERBOSE
          Dir.foreach(hook_files) do |file_path|
            if file_path.match(/\.rb$/)
              hook_commands += "if [ $? -eq 0 ]; then ruby #{File.join(ruby_hook_dir, ruby_hook_file, file_path)} \"$@\"; else exit 1; fi\n"
            end
          end
          hook_content += "#{GIT_HOOK_INSTALL_LINE_BEGIN}\n#{hook_commands}\n#{GIT_HOOK_INSTALL_LINE_END}"
          File.open(git_hook, 'w+') do |file|
            file.write(hook_content)
          end
          FileUtils.chmod(0744, git_hook)
        end
      end
    end

  end
end
