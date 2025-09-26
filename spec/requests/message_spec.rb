# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profiles', type: :request do
  let!(:user_one) { User.first }
  let!(:profile_one) { user_one.profiles.first }
  let!(:wall_one) { create(:wall, parent: profile_one) }
  let!(:message_one) { create(:message, profile: profile_one, target: profile_one, wall: wall_one, target_type: '') }

  before do
    create(:message_viewer, message: message_one, poster_profile: profile_one,
                            viewer_profile: profile_one)
    create(:feed, wall_id: wall_one.id, profile: profile_one)
  end

  context 'when GET /message' do
    it 'redirects to login if unauthenticated' do
      get url_for controller: 'message', action: :index
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders message list' do
      sign_in user_one
      get url_for controller: 'message', action: :index
      expect(response.status).to eq(200)
      expect(response.body).to include message_one.content
    end
  end

  context 'when POST /message/save' do
    it 'redirects to login if unauthenticated' do
      post url_for controller: 'message', action: :save
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'saves a new message' do
      sign_in user_one
      message_text = Faker::Lorem.sentence
      post url_for(controller: 'message', action: :save),
           params: FactoryBot.attributes_for(:message, content: message_text, profile: profile_one, target: profile_one,
                                                       wall: wall_one,
                                                       target_type: '')
                             .merge({ parent_id: profile_one.id })

      expect(response.status).to eq(200)
      expect(response.body).to include message_text
    end
  end
end
