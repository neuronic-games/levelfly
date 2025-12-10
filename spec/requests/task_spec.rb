# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tasks' do
  let!(:course_one) { create(:course, school: school_demo, owner: profile_one) }
  let!(:task_one) { create(:task, school: school_demo, course: course_one) }

  before do
    create(:task_participant, task: task_one, profile: profile_one, profile_type: Task.profile_type_owner)
  end

  context 'when GET /index' do
    let(:params) { { course_id: course_one.id } }

    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'task', action: :index),
          params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders index page' do
      sign_in user_one
      get url_for(controller: 'task', action: :index),
          params: params
      expect(response.body).to include task_one.name
    end
  end

  context 'when GET /show' do
    let(:params) { { id: task_one.id } }
    let(:url) { url_for(controller: 'task', action: :show) }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders task details page' do
      sign_in user_one
      get url, params: params
      expect(response.body).to include task_one.name
    end
  end

  context 'when POST /save' do
    let(:task_name) { Faker::Lorem.sentence }
    let(:params) { { task: task_name, course_id: course_one.id, school_id: school_demo.id } }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'task', action: :save),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'saves a new task' do
      sign_in user_one
      post url_for(controller: 'task', action: :save),
           params: params

      expect(response).to have_http_status(:ok)
      expect(response.body).to include task_name
    end
  end
end
