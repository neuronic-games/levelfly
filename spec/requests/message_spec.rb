# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profiles', type: :request do
  before(:all) do
    @user = User.first
    @school_demo = School.find_by!(handle: 'demo')
    @profile = @user.profiles.first
    @wall = FactoryGirl.create(:wall, parent: @profile)
    @feed = FactoryGirl.create(:feed, wall_id: @wall.id, profile: @profile)

    @message = FactoryGirl.create(:message, profile: @profile, target: @profile, wall: @wall, target_type: '')
    @message_viewer = FactoryGirl.create(:message_viewer, message: @message, poster_profile: @profile,
                                                          viewer_profile: @profile)
  end

  context 'GET /message' do
    it 'should redirect to login if unauthenticated' do
      get url_for controller: 'message', action: :index
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render user profile page' do
      sign_in @user
      get url_for controller: 'message', action: :index
      expect(response.status).to eq(200)
      expect(response.body).to include @message.content
    end
  end

  context 'POST /message/save' do
    it 'should redirect to login if unauthenticated' do
      post url_for controller: 'message', action: :save
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should save a new message' do
      sign_in @user
      message_text = Faker::Lorem.sentence
      post url_for(controller: 'message', action: :save),
           params: FactoryGirl.attributes_for(:message, content: message_text, profile: @profile, target: @profile, wall: @wall,
                                                        target_type: '')
                              .merge({ parent_id: @profile.id })

      expect(response.status).to eq(200)
      expect(response.body).to include message_text
    end
  end
end
