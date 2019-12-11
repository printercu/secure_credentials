require 'secure_credentials/credentials'
require 'secure_credentials/store'

module SecureCredentials
  module Rails
    # Provides patch for Rails::Application, to make it use SecureCredentials
    # as a replacement for built-in `#credentials` and `#secrets`.
    module ApplicationMethods
      def secrets
        @secrets ||= read_secure_credentials('config/secrets')
      end

      def credentials
        @credentials ||= read_secure_credentials('config/credentials')
      end

      def read_secure_credentials(path, key_path: nil, **options)
        # Unlike Rails we don't provide default value for key_path
        # to be able to generate it based on path.
        key_path &&= ::Rails.root.join(key_path)
        store = Store.new(::Rails.root.join(path), key_path: key_path, env: ::Rails.env, **options)
        Credentials.new(store)
      end

      # Override default #credentials method.
      alias_method :encrypted, :read_secure_credentials
    end
  end
end
