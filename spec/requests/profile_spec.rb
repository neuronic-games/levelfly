# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profiles', type: :request do
  before(:all) do
    @user = User.first
    @school_demo = School.find_by!(handle: 'demo')
    @profile = @user.profiles.first

    # NOTE: See note in ./course_spec.rb
    @user_two = FactoryBot.create(:user, default_school: @school_demo)
    @profile_two = FactoryBot.create(:profile, user: @user_two, school: @school_demo)
  end

  after(:all) do
    @user_two.delete
    @profile_two.delete
  end

  context 'GET /user_profile' do
    it 'redirects to login if unauthenticated' do
      get url_for controller: 'profile', action: :user_profile
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders user profile page' do
      sign_in @user
      get url_for controller: 'profile', action: :user_profile
      expect(response.body).to include @profile.full_name
    end

    it "renders other user's user profile page" do
      sign_in @user
      get url_for(controller: 'profile', action: :user_profile),
          params: { profile_id: @profile_two.id }
      expect(response.body).to include @profile_two.full_name
    end
  end

  context 'POST /save' do
    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'profile', action: :save),
           params: FactoryBot.attributes_for(:profile)
      expect(response).to redirect_to '/users/sign_in'
    end

    # TODO: test profile save
  end
end
