helpers do
	def json_response(status_code, body)
		status status_code
		content_type :json
		JSON.generate(body)
	end

	def authenticate_device!
		device_id = session[:device_id]
		registry = settings.device_registry

		# might as well ensure device still exists in registry
		unless device_id && registry.find(device_id)
			if request.path.start_with?("/api/")
				halt 401, json_response(401, error: "unauthenticated")
			else
				redirect "/login"
			end
		end

		device_id
	end
end



configure_routes do
	get "/" do
		device = authenticate_device!
		@scripts = SCRIPTS.keys.map(&:to_s)
		erb :root
	end
	
	get "/login" do
		redirect "/" if session[:device_id] && settings.device_registry.find(session[:device_id])

		erb :login
	end

	post "/api/auth/check" do
		device_id = request.env["HTTP_X_DEVICE_ID"].to_s
		authorization = request.env["HTTP_AUTHORIZATION"].to_s

		token = if authorization.start_with?("Bearer ")
			authorization.delete_prefix("Bearer ").strip
		end

		registry = settings.device_registry

		unless token && registry.authenticate(device_id, token)
			halt 401, json_response(401, ok: false, error: "invalid_credentials")
		end

		# prevent session fixation by replacing pre-login session
		session.clear
		session[:device_id] = device_id

		json_response(200, ok: true, device_id: device_id)
	end
	
	
	post "/api/actions/:action" do
		device = authenticate_device!
		action = params[:action]

		unless SCRIPTS.key?(action)
			halt 403, JSON.generate(error: "action_not_allowed")
		end

		script = File.expand_path(SCRIPTS.fetch(action), __dir__+"/../")
		puts script

		unless File.file?(script)
			halt 500, JSON.generate(error: "script_not_found")
		end

		# never accept a script path or AppleScript source from the client!
		stdout, stderr, result = Open3.capture3(
			"/usr/bin/osascript", script
		)

		unless result.success?
			warn "AppleScript failed for #{action}: #{stderr}"
			halt 500, JSON.generate(error: "action_failed")
		end

		JSON.generate(
			ok: true,
			action: action,
			request_id: SecureRandom.uuid
		)
	end
end