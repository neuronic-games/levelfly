# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Badges' do
  context 'when POST /give_badges' do
    let!(:course_one) { create(:course, school: school_demo, owner: profile_one) }
    let!(:user_two) { create(:user, default_school: school_demo) }
    let!(:profile_two) { create(:profile, user: user_two, school: school_demo) }

    let(:url) { url_for(controller: 'badge', action: :give_badges) }
    let(:params) { { course_id: course_one.id, profile_id: profile_two.id } }

    before do
      create(:participant, target: course_one, target_type: 'Course', profile: profile_one,
                           profile_type: 'M')
      create(:participant, target: course_one, target_type: 'Course', profile: profile_two,
                           profile_type: 'S')
    end

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'gives a badge to the specified user' do
      sign_in user_one
      post url, params: params
      expect(response).to render_template 'badge/_give_badges'
    end
  end
end
