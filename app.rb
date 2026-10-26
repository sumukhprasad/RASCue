require "sinatra/base"
require_relative "script-manifest"
require_relative "device-registry"

SCRIPTS = generate_script_manifest.freeze

class RASCue < Sinatra::Base
     enable :sessions
     set :session_secret, SecureRandom.hex(64)
		
	set :views, File.expand_path("views", __dir__)
	set :public_folder, File.expand_path("public", __dir__)
	
	# not the most secure, but eh it works.
	def self.configure_routes(&block)
		class_eval(&block)
	end
	
	def self.setup_devices
		print "How many devices should be registered? "

		input = $stdin.gets
		abort "No input received!" unless input

		count = Integer(input, 10)
		abort "Device count must be between 1 and 100" unless (1..100).cover?(count)

		registry = DeviceRegistry.new(count: count)
		registry.print_devices

		set :device_registry, registry
	rescue ArgumentError
		abort "please enter a valid integer between 1 and 100"
	end
	
	
	Dir[File.join(__dir__, "routes", "*.rb")].each do |route_file|
		class_eval(File.read(route_file), route_file)
	end
end
