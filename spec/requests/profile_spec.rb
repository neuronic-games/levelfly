# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profiles' do
  let!(:user_two) { create(:user, default_school: school_demo) }
  let!(:profile_two) { create(:profile, user: user_two, school: school_demo) }

  context 'when GET /user_profile' do
    let(:url) { url_for controller: 'profile', action: :user_profile }

    it 'redirects to login if unauthenticated' do
      get url
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders user profile page' do
      sign_in user_one
      get url
      expect(response.body).to include profile_one.full_name
    end

    it "renders other user's user profile page" do
      sign_in user_one
      get url,
          params: { profile_id: profile_two.id }
      expect(response.body).to include CGI.escapeHTML(profile_two.full_name)
    end
  end

  context 'when POST /save' do
    let(:url) { url_for(controller: 'profile', action: :save) }
    let!(:avatar) { create(:avatar, profile: profile_one) }
    let(:params) do
      {
        profile: attributes_for(:profile, code: 'DEFAULT').merge({
                                                                   school_id: school_demo.id
                                                                 }),
        avatar: attributes_for(:avatar),
        avatar_img: Base64.encode64(File.open('app/assets/images/rails.png', 'rb').read)
      }
    end

    it 'redirects to login if unauthenticated' do
      post url,
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'creates a new profile' do
      sign_in user_one

      profile_count = Profile.count

      post url,
           params: params

      expect(response).to have_http_status :ok
      expect(Profile.count).to eq(profile_count + 1)
      expect(json_body['profile']['user_id']).to eq(user_one.id)
      # TODO: Could test some more stuff here
    end

    it 'edits existing profile' do
      sign_in user_one

      new_major = Faker::Number.number(digits: 1)

      post url,
           params: params.update({
                                   id: profile_one.id,
                                   profile: params[:profile].update(
                                     code: profile_one.code,
                                     school_id: school_demo.id,
                                     major_id: new_major
                                   )
                                 })

      profile_one.reload
      expect(profile_one.major_id).to eq(new_major)
      # TODO: Test more things?
    end
  end
end
