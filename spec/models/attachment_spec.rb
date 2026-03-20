# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Attachment do
  it 'has a valid factory' do
    expect(build(:attachment)).to be_valid
  end

  context 'when connected to AWS' do
    let(:school_demo) { School.find_by!(handle: 'demo') }
    let(:profile_one) { User.first.profiles.first }
    let(:filename) { Faker::File.file_name(ext: 'png') }
    let(:file_demo) { 'app/assets/images/rails.png' }

    # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    it 'uploads an image to default bucket, accesses it, then deletes it' do
      expect do
        attachment = described_class.new(school_id: school_demo.id, owner: profile_one)
        attachment.resource.attach(io: File.open(file_demo), filename: filename)
        attachment.save
      end.not_to raise_error

      attachment = described_class.first

      uploaded_hash = Digest::SHA2.hexdigest described_class.get_file_data(attachment)
      test_hash = Digest::SHA2.hexdigest File.read(file_demo)

      expect(uploaded_hash).to eq(test_hash)

      expect do
        attachment&.resource&.purge
      end.not_to raise_error
    end
    # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations

    it 'uploads a base64 image' do
      file_content = File.read(file_demo)
      encoded_content = Base64.strict_encode64(file_content)

      attachment = described_class.upload_base64(school_demo.id, filename, encoded_content)
      attachment.save

      uploaded_hash = Digest::SHA2.hexdigest described_class.get_file_data(attachment)
      test_hash = Digest::SHA2.hexdigest File.read(file_demo)

      expect(uploaded_hash).to eq(test_hash)
    end
  end
end
