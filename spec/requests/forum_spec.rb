# frozen_string_literal: true

# NOTE: Forums exist within courses; they are broken out here because course_spec.rb is already almost 700 lines 🫠

require 'rails_helper'

RSpec.describe 'Forums' do
  let!(:forum_one) { create(:course, :forum, school: school_demo, owner: profile_one) }
  let!(:user_two) { create(:user, default_school: school_demo) }
  let!(:profile_two) { create(:profile, user: user_two, school: school_demo) }

  context 'when POST /forum_member_unchecked' do
    let(:url) { url_for(controller: 'course', action: :forum_member_unchecked) }
    let(:params) { { id: forum_one.id } }

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'handles forum member unchecked action' do
      sign_in user_one
      post url, params: params
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when GET /new_forum' do
    let(:url) { url_for(controller: 'course', action: :new_forum) }
    let(:params) { { id: forum_one.id } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders new forum page' do
      sign_in user_one
      get url, params: params
      expect(response).to have_http_status(:ok)
      expect(response.body).to render_template 'course/_forum_setup'
    end
  end

  context 'when POST /save_forum' do
    let(:url) { url_for(controller: 'course', action: :save_forum) }
    let(:params) do
      {
        id: forum_one.id,
        name: Faker::Lorem.sentence,
        descr: Faker::Lorem.paragraph
      }
    end

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies edit from unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in course_controller.rb'
      sign_in user_two
      post url, params: params
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates new forum' do
      sign_in user_one
      post url, params: params.merge!({ id: nil })
      expect(response).to have_http_status(:ok)
      expect(json_body['course']['name']).to eq(params[:name])
      expect(json_body['course']['descr']).to eq(params[:descr])
      expect(Course.count).to eq(2)
    end

    it 'updates existing forum' do
      sign_in user_one
      post url, params: params
      expect(response).to have_http_status(:ok)
      forum_one.reload
      expect(forum_one.name).to eq(params[:name])
      expect(forum_one.descr).to eq(params[:descr])
      expect(Course.count).to eq(1)
    end
  end

  context 'when GET /show_forum' do
    let(:url) { url_for(controller: 'course', action: :show_forum) }
    let(:params) { { id: forum_one.id } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders forum show page' do
      # FIXME: Test auth
      # FIXME: Test cross-school behaviour
      sign_in user_one
      get url, params: params
      expect(response).to have_http_status(:ok)
      expect(response.body).to include 'forum'
    end
  end

  context 'when GET /view_forum_setup' do
    let(:url) { url_for(controller: 'course', action: :view_forum_setup) }
    let(:params) { { id: forum_one.id } }

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders forum setup page' do
      sign_in user_one
      post url, params: params
      expect(response).to have_http_status(:ok)
      expect(response.body).to render_template 'course/_forum_setup'
    end
  end
end
