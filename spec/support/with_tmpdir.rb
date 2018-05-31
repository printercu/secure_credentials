require 'tmpdir'

RSpec.shared_context 'with_tmpdir' do
  around do |ex|
    Dir.mktmpdir do |dir|
      @tmpdir = Pathname.new(dir)
      ex.run
    end
  end

  attr_reader :tmpdir
end

RSpec.configure do |config|
  config.include_context 'with_tmpdir', :with_tmpdir
end
