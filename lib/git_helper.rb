class GitHelper
	def initialize(repo_path)
		@repo_path = repo_path
	end

	def clone_or_update
		if File.directory? File.join(@repo_path, '.git')
			exec_shell 'git pull'
		else
			exec_shell "git clone #{ENV['PROXY_CONFIG_REPO']} #{@repo_path}", false
		end
	end

	def add_proxy_files
		result = `cd #{@repo_path} && git status --porcelain`
		unless $?.success?
			puts "ERROR: can not execute shell command: #{cmd}"
			exit 1
		end

		changes = 0
		result.split("\n").each do |line|
			state, file = line.split(' ')
			puts "'#{file}' | '#{state}'"
			next unless file.start_with? 'haproxy/'

			if %w(M ??).include? state
				exec_shell "git add #{file}"
				changes += 1
			elsif 'D'.eql? state
				exec_shell "git rm #{file}"
				changes += 1
			end
		end

		if changes > 0
			puts 'Committing changes'
			exec_shell 'git commit -m "[watcher] Updated haproxy.cfg"'
			exec_shell 'git push'
		else
			 puts 'No changes detected'
		end
	end

	private

	def exec_shell(cmd, do_cd = true)
		puts "Executing: #{cmd}"
		cmd = "cd #{@repo_path} && #{cmd}" if do_cd
		puts `#{cmd}`
		unless $?.success?
			puts "ERROR: can not execute shell command: #{cmd}"
			exit 1
		end
	end
end
