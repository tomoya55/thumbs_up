if defined?(Rails.logger)
  Rails.logger.info "** thumbs_up: setting up load paths **"
elsif defined?(RAILS_DEFAULT_LOGGER)
  RAILS_DEFAULT_LOGGER.info "** thumbs_up: setting up load paths **"
end

%w{ models controllers helpers }.each do |dir|
  path = File.join(File.dirname(__FILE__) , 'lib', dir)
  $LOAD_PATH << path
  ActiveSupport::Dependencies.autoload_paths << path
  ActiveSupport::Dependencies.autoload_once_paths.delete(path)
end

require 'thumbs_up'