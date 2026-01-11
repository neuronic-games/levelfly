# frozen_string_literal: true

require 'rails_helper'

# NOTE: In the UI as "People"

RSpec.describe 'Users' do
  let(:url) { url_for controller: 'users', action: :index }

  context 'when GET /index' do
    it 'redirects to login if unauthenticated' do
      get url
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders index page' do
      sign_in user_one
      get url,
          xhr: true
      expect(response.body).to include profile_one.full_name
    end
  end

  context 'when POST /set_invite_codes' do
    let(:url) { url_for(controller: 'users', action: :set_invite_codes) }
    let(:params) { { student_code: Faker::Alphanumeric.alpha, teacher_code: Faker::Alphanumeric.alpha } }

    it 'redirects to login if unauthenticated' do
      post url,
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'sets invite codes' do
      sign_in user_one
      post url,
           params: params
      expect(json_body['status']).to be true

      # TODO: Test that duplicate codes can't be set
    end
  end

  context 'when GET /load_users' do
    let!(:course_one) { create(:course, school: school_demo, owner: profile_one) }
    let(:url) { url_for(controller: 'users', action: :load_users, id: course_one.id, page: 1) }

    it 'redirects to login if unauthenticated' do
      get url
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'lists users' do
      sign_in user_one
      get url
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(profile_one.full_name)
    end
  end
end
