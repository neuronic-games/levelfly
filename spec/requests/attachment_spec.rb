# frozen_string_literal: true

# NOTE: This is intended as a smoke-test of file upload functionality completely breaking.
# Perhaps in the fullness of time, each type of upload will be tested with the rest of each controller's methods

require 'rails_helper'

RSpec.describe 'Attachments' do
  let!(:user_one) { User.first }
  let!(:school_demo) { School.find_by!(handle: 'demo') }
  let!(:profile_one)  { user_one.profiles.first }
  let!(:course_one) { create(:course, school: school_demo, owner: profile_one) }
  let!(:participant_one) do
    create(:participant, target: course_one, target_type: 'Course', profile: profile_one,
                         profile_type: 'M')
  end

  context 'when POST /add_file' do
    it 'redirects to login if unauthenticated' do
      post url_for controller: 'course', action: :add_file
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'attaches file' do
      sign_in user_one

      post url_for(controller: 'course', action: :add_file),
           params: { file: Rack::Test::UploadedFile.new('app/assets/images/rails.png', 'image/png'), school_id: school_demo.id, id: course_one.id, target_type: 'Course', profile_id: profile_one.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include 'rails.png'

      expect(Attachment.count).to eq(1)
    end
  end
end
