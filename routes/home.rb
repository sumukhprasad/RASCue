configure_routes do
	get "/" do
		@scripts = SCRIPTS.keys.map(&:to_s)
		erb :root
	end
end