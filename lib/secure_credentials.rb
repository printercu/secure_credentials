require 'secure_credentials/version'

# Makes it possible to use best of encrypted credentials
# and environment-dependent secrets. Sharing encryption keys with
# every developer in a team is a security issue, and purpose of this gem
# is to help you to avoid it.
module SecureCredentials
  class FileNotFound < StandardError; end
end

require 'secure_credentials/store'
require 'secure_credentials/credentials'
require 'secure_credentials/rails' if defined?(Rails)
