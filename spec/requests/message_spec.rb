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

      expect(response.body).to include 'I\'d like to be your friend.'
    end
  end

  context 'when POST /message/respond_to_course_request' do
    let!(:course_one) { create(:course, school: school_demo, owner: profile_one) }
    let!(:user_two) { create(:user, default_school: school_demo) }
    let!(:profile_two) { create(:profile, user: user_two, school: school_demo) }
    let!(:participant_two) { create(:participant, target: course_one, profile: profile_two, profile_type: 'P')}
    let!(:message_two) do
      create(:message, profile: profile_one, parent_id: profile_two.id, parent_type: 'Course', target: course_one,
                       wall: wall_one, target_type: 'Course', message_type: 'course_invite')
    end
    let(:params) { { message_id: message_two.id, activity: 'add', message_type: 'course_invite', section_type: 'Course' } }
    let(:url) { url_for(controller: 'message', action: :respond_to_course_request, params: params) }

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'accepts course invitation' do
      sign_in user_one

      post url, params: params

      expect(response.body).to include "Added to #{course_one.name}"
      participant_two.reload
      expect(participant_two.profile_type).to eq('S')
    end
  end

  context 'when POST /delete_message' do
    let!(:wall_two) { create(:wall, parent: course_one, parent_type: 'C') }
    let!(:course_one) { create(:course, school: school_demo, owner: profile_one) }
    let!(:message_two) do
      create(:message, parent: course_one, parent_type: 'C', target: course_one, wall: wall_two, target_type: 'C',
                       message_type: Message.to_s, profile: profile_one)
    end
    let!(:message_three) do
      create(:message, parent: message_two, parent_type: Message.to_s, target: course_one, wall: wall_two, target_type: 'C',
                       message_type: Message.to_s, profile: profile_one)
    end

    let(:url) { url_for(controller: 'message', action: :delete_message) }
    # TODO: Test `delete_all`
    let(:params) { { id: message_two.id } }

    before do
      create(:message_viewer, message: message_two, poster_profile: profile_one,
                              viewer_profile: profile_one)
    end

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'deletes a message, not notifying friends' do
      sign_in user_one
      post url, params: params
      expect(json_body['status']).to be(true)
      message_two.reload
      message_three.reload
      expect(message_two.archived).to be(true)
      expect(message_three.archived).to be(true)
    end

    it 'deletes a message, notifying friends' do
      sign_in user_one
      post url, params: params.merge({ message_friends: 'true' })
      expect(json_body['status']).to be(true)
      message_two.reload
      message_three.reload
      expect(message_two.archived).to be(true)
      expect(message_three.archived).to be(true)
    end
  end

  # NOTE: "Confirm delete" pop-up
  context 'when POST /message/confirm' do
    let!(:course_one) { create(:course, school: school_demo, owner: profile_one) }
    let!(:wall_two) { create(:wall, parent: course_one, parent_type: 'C') }
    let!(:message_two) { create(:message, profile: profile_one, target: profile_one, wall: wall_two, target_type: 'C') }
    let(:url) { url_for(controller: 'message', action: :confirm) }
    let(:params) { { course_master_id: profile_one.id, id: message_two.id } }
    # FIXME: add second user, profile, message

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'warns about trying to delete a thread with replies from others' do
      sign_in user_one
      post url, params: params
      # FIXME: Test content
    end
  end
end
