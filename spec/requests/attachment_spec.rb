# frozen_string_literal: true

# NOTE: This is intended as a smoke-test of file upload functionality completely breaking.
# Perhaps in the fullness of time, each type of upload will be tested with the rest of each controller's methods

require 'rails_helper'

RSpec.describe 'Attachments' do
  let(:course_one) { create(:course, school: school_demo, owner: profile_one) }
  let(:user_two) { create(:user, default_school: school_demo) }

  before do
    create(:participant, target: course_one, target_type: 'Course', profile: profile_one,
                         profile_type: 'M')
  end

  context 'when GET /course/download' do
    let(:attachment) { create(:attachment, target: course_one, target_type: 'Course') }
    let(:params) { { id: attachment.id } }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :download),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in course_controller.rb'
      sign_in user_two

      post url_for(controller: 'course', action: :download),
           params: params

      expect(response.status).to eq(:forbidden)
    end

    it 'shows file download dialog' do
      sign_in user_one

      post url_for(controller: 'course', action: :download),
           params: params

      expect(response).to render_template 'course/_download_dialog'
    end
  end

  context 'when POST /course/add_file' do
    let(:params) { { file: Rack::Test::UploadedFile.new('app/assets/images/rails.png', 'image/png'), school_id: school_demo.id, id: course_one.id, target_type: 'Course', profile_id: profile_one.id } }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :add_file),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'attaches file' do
      sign_in user_one

      post url_for(controller: 'course', action: :add_file),
           params: params

      expect(response).to have_http_status(:ok)
      expect(response.body).to include 'rails.png'

      expect(Attachment.count).to eq(1)
    end
  end

  context 'when POST /course/toggle_priority_file' do
    let(:attachment_starred) { create(:attachment, target: course_one, target_type: 'Course', starred: true) }
    let(:attachment_unstarred) { create(:attachment, target: course_one, target_type: 'Course', starred: false) }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :toggle_priority_file),
           params: { id: attachment_starred.id }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in course_controller.rb'
      sign_in user_two

      post url_for(controller: 'course', action: :toggle_priority_file),
           params: { id: attachment_starred.id }

      expect(response).to have_http_status(:forbidden)
      attachment_starred.reload
      expect(attachment_starred.starred).to be true
    end

    it 'toggles file star status' do
      sign_in user_one

      post url_for(controller: 'course', action: :toggle_priority_file),
           params: { id: attachment_starred.id }

      expect(response).to have_http_status(:ok)

      attachment_starred.reload
      expect(attachment_starred.starred).to be false


      expect(json_body['starred']).to be false

      post url_for(controller: 'course', action: :toggle_priority_file),
           params: { id: attachment_unstarred.id }

      expect(response).to have_http_status(:ok)

      attachment_unstarred.reload
      expect(attachment_unstarred.starred).to be true


      expect(json_body['starred']).to be true
    end
  end
end
