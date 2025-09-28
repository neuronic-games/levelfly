# frozen_string_literal: true

require 'rails_helper'

# NOTE: In the UI as "People"

RSpec.describe 'Users' do
  context 'when GET /index' do
    it 'redirects to login if unauthenticated' do
      get url_for controller: 'users', action: :index
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders index page' do
      sign_in user_one
      get url_for(controller: 'users', action: :index),
          xhr: true
      expect(response.body).to include profile_one.full_name
    end
  end

  context 'when POST /set_invite_codes' do
    let(:params) { { student_code: Faker::Alphanumeric.alpha, teacher_code: Faker::Alphanumeric.alpha } }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'users', action: :set_invite_codes),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'sets invite codes' do
      sign_in user_one
      post url_for(controller: 'users', action: :set_invite_codes),
           params: params
      response_parsed = JSON.parse(response.body)
      expect(response_parsed['status']).to be true

      # TODO: Test that duplicate codes can't be set
    end
  end
end
