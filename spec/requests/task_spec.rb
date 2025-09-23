# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tasks', type: :request do
  before(:all) do
    @user = User.first
    @school_demo = School.find_by!(handle: 'demo')
    @profile = @user.profiles.first

    @course = FactoryBot.create(:course, school: @school_demo, owner: @profile)
    @task = FactoryBot.create(:task, school: @school_demo, course: @course)
    @task_participant = FactoryBot.create(:task_participant, task: @task, profile: @profile)
  end

  after(:all) do
    @task.delete
    @course.delete
  end

  context 'GET /index' do
    it 'should redirect to login if unauthenticated' do
      get url_for(controller: 'task', action: :index),
          params: { course_id: @course.id }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render index page' do
      sign_in @user
      get url_for(controller: 'task', action: :index),
          params: { course_id: @course.id }
      expect(response.body).to include @task.name
    end
  end

  context 'POST /save' do
    it 'should redirect to login if unauthenticated' do
      post url_for controller: 'task', action: :save
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should save a new task' do
      sign_in @user
      task_name = Faker::Lorem.sentence
      post url_for(controller: 'task', action: :save),
        params: { task: task_name, course_id: @course.id, school_id: @school_demo.id }

      expect(response.status).to eq(200)
      expect(response.body).to include task_name
    end
  end
end
