def generate_script_manifest
	manifest = Hash.new
	scripts = Dir["./scripts/*.scpt"].each do |s|
		manifest[File.basename(s)[0..-6]] = s;
	end
	
	return manifest
end