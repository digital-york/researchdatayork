# load dlibhydra config
DLIBHYDRA = YAML.load(File.read(File.expand_path('../../dlibhydra.yml', __FILE__))).with_indifferent_access
