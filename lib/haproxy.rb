class Haproxy
	attr_reader :node_ip, :haproxy, :combined_sites

	def initialize(node_ip, config, base_dir, client)
		@node_ip = node_ip
		@haproxy = config['haproxy']
		@combined_sites = @haproxy['sites']
		@base_dir = base_dir
		@template = File.join(base_dir, 'templates', 'haproxy.cfg.erb')
		@services = client.get_services
	end

	def service_backends(select_service)
		result = []

		@services.each do |service|
			#puts "#{service.metadata.namespace} - #{service.metadata.name}"
			next unless select_service['namespace'].eql? service.metadata.namespace
			next unless select_service['name'].eql? service.metadata.name

			result << "#{service.spec.clusterIP}:#{select_service['port']} check inter 5000 rise 2 fall 5"
		end

		puts "ERROR: No service found for #{select_service.inspect}!!" if result.empty?

		result
	end

	def basic_auth_config
		File.read File.join(@base_dir, 'proxy-config', 'basic-auth.cfg')
	end

	def render
		content = File.read(@template).gsub('###BASIC-AUTH-CONFIG###', basic_auth_config)
		ERB.new(content, nil, '-').result(binding)
	end

	def write(file)
		File.write file, self.render
	end
end
