# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profiles' do
  let!(:user_one) { User.first }
  let!(:school_demo) { School.find_by!(handle: 'demo') }
  let!(:profile_one) { user_one.profiles.first }

  let!(:user_two) { create(:user, default_school: school_demo) }
  let!(:profile_two) { create(:profile, user: user_two, school: school_demo) }

  context 'when GET /user_profile' do
    it 'redirects to login if unauthenticated' do
      get url_for controller: 'profile', action: :user_profile
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders user profile page' do
      sign_in user_one
      get url_for controller: 'profile', action: :user_profile
      expect(response.body).to include profile_one.full_name
    end

    it "renders other user's user profile page" do
      sign_in user_one
      get url_for(controller: 'profile', action: :user_profile),
          params: { profile_id: profile_two.id }
      expect(response.body).to include CGI.escapeHTML(profile_two.full_name)
    end
  end

  context 'when POST /save' do
    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'profile', action: :save),
           params: attributes_for(:profile)
      expect(response).to redirect_to '/users/sign_in'
    end

    # TODO: test profile save
  end
end
