class Watcher
	def initialize(base_dir, config, git_helper)
		@base_dir = base_dir
		@config = config
		@git_helper = git_helper

		auth_options = {
			bearer_token: config['kubernetes']['bearer_token']
		}
		timeouts = {
			open: 10,  # unit is seconds
			read: nil  # nil means never time out
		}
		@client = Kubeclient::Client.new config['kubernetes']['uri'], config['kubernetes']['version'],
																		auth_options: auth_options, timeouts: timeouts
		@proxy_config_dir = File.join(base_dir, 'proxy-config')
		@config_dir = File.join(base_dir, 'proxy-config', 'haproxy')

		# Make sure directory exists
		FileUtils.mkdir @config_dir unless File.directory? @config_dir
	end

	def watch
		puts 'Starting watch'
		while true
			watcher = @client.watch_events
			watcher.each do |notice|
				next if %w(cattle-system kube-system).include? notice.object.metadata.namespace
				puts '*' * 100
				puts notice.inspect

				update
			end
		end
	end

	def update
		update_haproxy_cfg
		@git_helper.add_proxy_files
	end

	private

	def update_haproxy_cfg
		puts 'Creating haproxy files'

		@config['nodes'].each_pair do |node_name, node_ip|
			puts "Generating haproxy.conf for #{node_name}"
			haproxy = Haproxy.new node_ip, @config, @base_dir, @client
			haproxy.write File.join(@config_dir, "#{node_name}-haproxy.cfg")
		end
	end
end
