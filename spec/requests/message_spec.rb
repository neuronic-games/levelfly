# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Messages', type: :request do
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
      expect(response).to have_http_status(:ok)
      expect(response.body).to include message_one.content
    end
  end

  context 'when POST /message/save' do
    let(:message_text) { Faker::Lorem.sentence }
    let(:params) do
      FactoryBot.attributes_for(:message, content: message_text, profile: profile_one, target: profile_one,
                                          wall: wall_one,
                                          target_type: '')
                .merge({ parent_id: profile_one.id })
    end

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'message', action: :save),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'saves a new message' do
      sign_in user_one
      post url_for(controller: 'message', action: :save),
           params: params

      expect(response).to have_http_status(:ok)
      expect(response.body).to include message_text
    end
  end

  context 'when POST /course/toggle_priority_message' do
    let(:params) { { id: message_one.id } }
    let(:url) { url_for(controller: 'course', action: :toggle_priority_message, params: params) }

    it 'redirects to login if unauthenticated' do
      post url
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in course_controller.rb'
      sign_in user_two

      post url

      expect(response).to have_http_status(:forbidden)
      message_one.reload
      expect(message_one.starred).to be false
    end

    it 'toggles message starred status' do
      sign_in user_one

      post url

      expect(response).to have_http_status(:ok)
      expect(json_body['starred']).to be true
      message_one.reload
      expect(message_one.starred).to be true

      message_two = create(:message, profile: profile_one, target: profile_one, wall: wall_one, target_type: '',
                                     starred: true)

      post url_for(controller: 'course', action: :toggle_priority_message),
           params: { id: message_two.id }

      expect(response).to have_http_status(:ok)
      expect(json_body['starred']).to be false

      message_two.reload
      expect(message_two.starred).to be false
    end
  end

  context 'when POST /message/add_friend_card' do
    let!(:user_two) { create(:user, default_school: school_demo) }
    let!(:profile_two) { create(:profile, user: user_two, school: school_demo) }
    let(:params) { { profile_id: profile_two.id } } 
    let(:url) { url_for(controller: 'message', action: :add_friend_card, params: params) }

    it 'redirects to login if unauthenticated' do
      post url
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders "add friend" card' do
      sign_in user_one

      post url

      require 'pry'; binding.pry
    end
  end
end
