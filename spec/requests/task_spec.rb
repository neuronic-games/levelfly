# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tasks' do
  let!(:user_one) { User.first }
  let!(:school_demo) { School.find_by!(handle: 'demo') }
  let!(:profile_one) { user_one.profiles.first }
  let!(:course_one) { create(:course, school: school_demo, owner: profile_one) }
  let!(:task_one) { create(:task, school: school_demo, course: course_one) }

  before do
    create(:task_participant, task: task_one, profile: profile_one)
  end

  context 'when GET /index' do
    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'task', action: :index),
          params: { course_id: course_one.id }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders index page' do
      sign_in user_one
      get url_for(controller: 'task', action: :index),
          params: { course_id: course_one.id }
      expect(response.body).to include task_one.name
    end
  end

  context 'when POST /save' do
    it 'redirects to login if unauthenticated' do
      post url_for controller: 'task', action: :save
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'saves a new task' do
      sign_in user_one
      task_name = Faker::Lorem.sentence
      post url_for(controller: 'task', action: :save),
           params: { task: task_name, course_id: course_one.id, school_id: school_demo.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include task_name
    end
  end
end
