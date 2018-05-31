unless defined?(RAILS_SECURE_CREDENTIALS_SKIP_PATCH)
  require 'secure_credentials/rails/application_methods'
  Rails::Application.prepend SecureCredentials::Rails::ApplicationMethods
end
