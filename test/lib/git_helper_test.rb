class TestGitHelper < Test::Unit::TestCase
	def setup
		$bare_source_git_repo = '/tmp/test-git-repo-source-bare'
		$source_git_repo = '/tmp/test-git-repo-source'
		$target_git_repo = '/tmp/test-git-proxy-repo'
		puts `rm -rf #{$bare_source_git_repo}`
		puts `rm -rf #{$source_git_repo}`
		puts `git init --bare #{$bare_source_git_repo}`
		puts `git clone #{$bare_source_git_repo} #{$source_git_repo}`
	end

	def teardown
		puts '-' * 100
		puts 'Teardown'
		puts `rm -rf #{$bare_source_git_repo}`
		puts `rm -rf #{$source_git_repo}`
		puts `rm -rf #{$target_git_repo}`
	end

	def test_clone_repo
		clean_proxy_repo
		ENV['PROXY_CONFIG_REPO'] = $bare_source_git_repo
		git_helper = GitHelper.new $target_git_repo
		git_helper.clone_or_update
		assert(File.directory?($target_git_repo), 'Proxy Repo not cloned')
		assert(File.directory?(File.join($target_git_repo, '.git')), 'Proxy Repo is not a git repository')
	end

	def test_update_repo
		clone_proxy_repo
		add_to_source_repo('haproxy/node1-haproxy.cfg', 'Test')
		git_helper = GitHelper.new $target_git_repo
		git_helper.clone_or_update

		assert(File.directory?(File.join($target_git_repo, 'haproxy')), 'haproxy directory does not exist')
		assert(File.exist?(File.join($target_git_repo, 'haproxy', 'node1-haproxy.cfg')), 'node1-haproxy.cfg file does not exist')
	end

	def test_commit_changed_file
		add_to_source_repo('haproxy/node1-haproxy.cfg', 'Test')
		git_helper = GitHelper.new $target_git_repo
		git_helper.clone_or_update

		puts `echo "Yeah! new content" >> #{File.join($target_git_repo, 'haproxy/node1-haproxy.cfg')}`
		git_helper.add_proxy_files

		check_git_status_empty
		content = File.read File.join($target_git_repo, 'haproxy/node1-haproxy.cfg')
		assert(content.include?('Yeah! new content'), 'File does not contain changes')
		update_source_repo
		content = File.read File.join($source_git_repo, 'haproxy/node1-haproxy.cfg')
		assert(content.include?('Yeah! new content'), 'File does not contain changes')
	end

	def test_commit_new_file
		add_to_source_repo('haproxy/node1-haproxy.cfg', 'Test')
		git_helper = GitHelper.new $target_git_repo
		git_helper.clone_or_update

		puts `echo "Yeah! new content" >> #{File.join($target_git_repo, 'haproxy/node2-haproxy.cfg')}`
		git_helper.add_proxy_files

		check_git_status_empty
		content = File.read File.join($target_git_repo, 'haproxy/node2-haproxy.cfg')
		assert(content.include?('Yeah! new content'), 'File does not contain changes')
		update_source_repo
		content = File.read File.join($source_git_repo, 'haproxy/node2-haproxy.cfg')
		assert(content.include?('Yeah! new content'), 'File does not contain changes')
	end

	def test_commit_removed_file
		add_to_source_repo('haproxy/node1-haproxy.cfg', 'Test')
		add_to_source_repo('haproxy/node2-haproxy.cfg', 'Test')
		git_helper = GitHelper.new $target_git_repo
		git_helper.clone_or_update

		FileUtils.rm File.join($target_git_repo, 'haproxy/node1-haproxy.cfg')
		git_helper.add_proxy_files

		check_git_status_empty
		assert(!File.exist?(File.join($target_git_repo, 'haproxy/node1-haproxy.cfg')), 'deleted file does still exist')
		update_source_repo
		assert(!File.exist?(File.join($source_git_repo, 'haproxy/node1-haproxy.cfg')), 'deleted file does still exist')
	end

	private

	def update_source_repo
		puts `cd #{$source_git_repo} && git pull`
	end

	def clean_proxy_repo
		puts `rm -rvf #{$target_git_repo}`
		assert(!File.directory?($target_git_repo), 'Failed cleaning proxy repo')
	end

	def clone_proxy_repo
		puts `git clone #{$bare_source_git_repo} #{$target_git_repo}`
	end

	def add_to_source_repo(file, content)
		full_file = File.join($source_git_repo, file)
		FileUtils.mkdir_p File.dirname(full_file)
		puts `echo "#{content}" > #{full_file}`
		puts `cd #{$source_git_repo} && git add #{file}`
		puts `cd #{$source_git_repo} && git commit -am "Added file"`
		puts `cd #{$source_git_repo} && git push`
	end

	def check_git_status_empty
		result = `cd #{$target_git_repo} && git status --porcelain`.strip
		assert(result.empty?, 'changes in the git repo detected!')
	end
end
