# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Attachment do
  it 'has a valid factory' do
    expect(build(:attachment)).to be_valid
  end

  context 'when connected to AWS' do
    let(:school_demo) { School.find_by!(handle: 'demo') }
    let(:filename) { Faker::File.file_name(ext: 'png') }
    let(:file_demo) { 'app/assets/images/rails.png' }

    # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    it 'uploads an image to default bucket, accesses it, then deletes it' do
      expect do
        described_class.aws_upload(school_demo.id, filename, file_demo)
      end.not_to raise_error

      expect do
        expect(described_class.aws_get_file_data(school_demo.id, filename)).to eq(File.read(file_demo))
      end.not_to raise_error

      expect do
        described_class.aws_delete_file(school_demo.id, filename)
      end.not_to raise_error
    end
    # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations

    it 'uploads a base64 image to default bucket' do
      file_content = File.read(file_demo)
      encoded_content = Base64.strict_encode64(file_content)

      expect do
        described_class.aws_upload_base64(school_demo.id, 'levelfly', filename, encoded_content)
      end.not_to raise_error
    end
  end
end
