# frozen_string_literal: true

# NOTE: Groups are a special case of Courses, so in theory these tests could also live in ./course_spec.rb
# – but it was already getting rather long!

require 'rails_helper'

RSpec.describe 'Groups', type: :request do
  let!(:group_one) { create(:course, :group, school: school_demo, owner: profile_one) }

  before do
    create(:participant, target: group_one, target_type: 'Course', profile: profile_one,
                         profile_type: 'M')
  end

  context 'when GET /Index' do
    it 'renders index page' do
      sign_in user_one
      get url_for controller: 'course', action: :index,
                  params: { section_type: 'G' }
      expect(response.body).to include group_one.name
    end
  end

  context 'when GET /view_group_setup' do
    let(:params) { { id: group_one.id } }

    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'course', action: :view_group_setup),
          params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'shows group setup page' do
      sign_in user_one

      get url_for(controller: 'course', action: :view_group_setup),
          params: params

      expect(response).to have_http_status(:ok)
      expect(response.body).to include CGI.escapeHTML(group_one.name)
    end
  end

  context 'when POST /filter' do
    let(:params) { { filter: 'M', section_type: Course.parent_type_group } }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :filter),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders filter results' do
      sign_in user_one

      user_two = create(:user, default_school: school_demo)
      profile_two = create(:profile, user: user_two, school: school_demo)
      group_two = create(:course, :group, school: school_demo, owner: profile_two)
      create(:participant, target: group_two, target_type: 'Course', profile: profile_two,
                           profile_type: 'M')

      post url_for(controller: 'course', action: :filter),
           params: params
      expect(response).to have_http_status(:ok)
      expect(response.body).to include group_one.name
      expect(response.body).not_to include group_two.name

      post url_for(controller: 'course', action: :filter),
           params: { filter: 'A', section_type: Course.parent_type_group }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include group_one.name
      expect(response.body).to include group_two.name
    end
  end

  context 'when POST /send_group_invitation' do
    let(:params) { { id: group_one.id } }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :send_group_invitation),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'sends a group invitation to a non-member' do
      user_two = create(:user, default_school: school_demo)
      profile_two = create(:profile, user: user_two, school: school_demo)

      sign_in user_two

      post url_for(controller: 'course', action: :send_group_invitation),
           params: params

      expect(response).to have_http_status(:ok)

      response_parsed = JSON.parse(response.body)

      expect(response_parsed['status']).to be true
      expect(profile_two.participants.first.profile_id).to eq(profile_two.id)
      expect(profile_two.participants.first.profile_type).to eq('P')
    end
  end

  context 'when POST /group_joinning' do
    let(:params) { { id: group_one.id, join_type: 'C' } }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :group_joinning),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'changes group joining setting' do
      sign_in user_one

      post url_for(controller: 'course', action: :group_joinning),
           params: params

      response_parsed = JSON.parse(response.body)

      group_one.reload
      expect(response_parsed['status']).to be true
      expect(group_one.join_type).to eq('C')
    end
  end

  context 'when POST /group_viewing' do
    let(:params) { { id: group_one.id, visibility_type: 'C' } }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :group_viewing),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'changes group visibility setting' do
      sign_in user_one

      post url_for(controller: 'course', action: :group_viewing),
           params: params

      response_parsed = JSON.parse(response.body)

      group_one.reload
      expect(response_parsed['status']).to be true
      expect(group_one.visibility_type).to eq('C')
    end
  end
end
