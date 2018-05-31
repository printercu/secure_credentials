RSpec.describe SecureCredentials::Store, :with_tmpdir do
  let(:instance) { described_class.new(path, inline_key, **instance_options) }
  let(:path) { tmpdir.join('secrets') }
  let(:inline_key) {}
  let(:instance_options) { {env: env} }
  let(:env) { :dev }
  let(:cipher) { SecureCredentials::EncryptedFile::CIPHER }

  def encrypt(content, key)
    encryptor = ActiveSupport::MessageEncryptor.new([key].pack('H*'), cipher: cipher)
    encryptor.encrypt_and_sign(content)
  end

  shared_examples 'accessing encrypted file' do |pass:, subject_is_proc: true|
    let(:encryption_key) { SecureCredentials::EncryptedFile.generate_key }
    let(:decryption_key) { encryption_key }
    let(:subject_proc) { subject_is_proc ? subject : -> { subject } }

    shared_examples 'invalid key' do
      context 'and is invalid' do
        let(:decryption_key) { SecureCredentials::EncryptedFile.generate_key }
        it { expect(&subject_proc).to raise_error ActiveSupport::MessageEncryptor::InvalidMessage }
      end
    end

    context 'when key is not given' do
      it { expect(&subject_proc).to raise_error SecureCredentials::EncryptedFile::MissingKeyError }
    end

    context 'when inline key is given' do
      let(:inline_key) { decryption_key }
      instance_exec(&pass)
      include_examples 'invalid key'
    end

    context 'when key file is present' do
      before { key_path.write(decryption_key) }
      instance_exec(&pass)
      include_examples 'invalid key'
    end

    context 'when key envvar is present' do
      let(:instance_options) { super().merge(env_key: env_key) }
      let(:env_key) { 'TEST_SECURE_CREDENTIALS_KEY' }
      around do |ex|
        begin
          ENV[env_key] = decryption_key
          ex.run
        ensure
          ENV.delete(env_key)
        end
      end
      instance_exec(&pass)
      include_examples 'invalid key'
    end
  end

  describe '#change' do
    subject { -> { instance.change { |file| file.write(new_content) } } }
    let(:old_content) { 'field: old_value' }
    let(:new_content) { 'field: new_value' }
    let(:other_env_file) { path.sub_ext('.prod.yml.enc') }

    context 'when encrypted file exists' do
      shared_examples 'updates file' do
        it 'updates this file' do
          should change { existing_file.read }.
            and not_change { other_env_file.read }
          expect(existing_file.read).to_not eq new_content
        end
      end

      let(:existing_file) { path.sub_ext('.yml.enc') }
      let(:key_path) { existing_file.sub_ext('').sub_ext('.key') }
      before do
        existing_file.write(encrypt(old_content, encryption_key))
        other_env_file.write(encrypt('other: something', encryption_key))
      end

      include_examples 'accessing encrypted file',
        pass: -> { include_examples 'updates file' }

      context 'for specific env' do
        let(:existing_file) { path.sub_ext(".#{env}.yml.enc") }
        include_examples 'accessing encrypted file',
          pass: -> { include_examples 'updates file' }
      end
    end

    context 'when plain file exists' do
      let(:existing_file) { path.sub_ext('.yml') }
      before do
        existing_file.write(old_content)
        other_env_file.write('other: something')
      end

      it 'updates this file' do
        should change { existing_file.read }.to(new_content).
          and not_change { other_env_file.read }
      end

      context 'for specific env' do
        let(:existing_file) { path.sub_ext(".#{env}.yml") }
        it 'updates this file' do
          should change { existing_file.read }.to(new_content).
            and not_change { other_env_file.read }
        end
      end
    end

    context 'when file does not exist' do
      let(:existing_file) { tmpdir.join('invalid.yml') }
      it { should raise_error SecureCredentials::FileNotFound }
    end
  end

  describe '#content' do
    subject { instance.content }
    let(:subject_proc) { -> { subject } }
    let(:file_content) { "dev:\n  field: value\ntest:\n  field: other" }
    let(:other_env_file) { path.sub_ext('.prod.yml.enc') }

    context 'when encrypted file exists' do
      let(:existing_file) { path.sub_ext('.yml.enc') }
      let(:key_path) { existing_file.sub_ext('').sub_ext('.key') }
      before do
        existing_file.write(encrypt(file_content, encryption_key))
        other_env_file.write(encrypt('other: something', encryption_key))
      end

      include_examples 'accessing encrypted file',
        subject_is_proc: false,
        pass: -> { it { should eq('field' => 'value') } }

      context 'for specific env' do
        let(:existing_file) { path.sub_ext(".#{env}.yml.enc") }
        include_examples 'accessing encrypted file',
          subject_is_proc: false,
          pass: -> { its(['dev']) { should eq('field' => 'value') } }
      end
    end

    context 'when plain file exists' do
      let(:existing_file) { path.sub_ext('.yml') }
      before do
        existing_file.write(file_content)
        other_env_file.write('other: something')
      end

      it { should eq('field' => 'value') }

      context 'for specific env' do
        let(:existing_file) { path.sub_ext(".#{env}.yml") }
        its(['dev']) { should eq('field' => 'value') }
      end
    end

    context 'when file does not exist' do
      let(:existing_file) { tmpdir.join('invalid.yml') }
      it { should eq({}) }
    end
  end
end
