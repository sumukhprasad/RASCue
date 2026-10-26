require "securerandom"

class DeviceRegistry
	Device = Struct.new(:id, :token, keyword_init: true)

	attr_reader :devices

	def initialize(count:)
		@devices = Array.new(count) do
			Device.new(
				id: "device_#{SecureRandom.hex(4)}",
				token: SecureRandom.hex(32)
			)
		end.freeze
	end

	def find(device_id)
		devices.find { |device| device.id == device_id }
	end

	def authenticate(device_id, token)
		device = find(device_id)
		return false unless device && token.is_a?(String)
		return false unless token.bytesize == device.token.bytesize

		require "rack/utils"
		Rack::Utils.secure_compare(device.token, token)
	end

	def print_devices
		puts "\n=== REGISTERED DEVICES ==="

		devices.each do |device|
			puts "device id: #{device.id}"
			puts "token: #{device.token}"
			puts
		end

		puts "===========================\n\n"
	end
end
