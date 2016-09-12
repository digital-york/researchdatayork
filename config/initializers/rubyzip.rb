# configuration for rubyzip (https://github.com/rubyzip/rubyzip)
require 'zip'
# allow rubyzip to overwrite files when it extracts an archive
Zip.on_exists_proc = true
