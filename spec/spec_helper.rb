require 'bundler/setup'
require 'pry'
require 'rspec/its'
require 'secure_credentials'

GEM_ROOT = Pathname.new File.expand_path('..', __dir__)
Dir[GEM_ROOT.join('spec', 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# for `.and not_change()`
RSpec::Matchers.define_negated_matcher :not_change, :change
