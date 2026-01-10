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
    let(:url) { url_for(controller: 'task', action: :index) }

    it 'redirects to login if unauthenticated' do
      get url,
          params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders index page' do
      sign_in user_one
      get url,
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
      get url, params: params, xhr: true
      expect(response.body).to include task_one.name
    end
  end

  context 'when POST /get_task' do
    # TODO: Also test non-blank `show`
    let(:url) { url_for(controller: 'task', action: :get_task) }

    let!(:task_two) { create(:task, school: school_demo, course: course_one) }

    before do
      create(:task_participant, task: task_two, profile: profile_one, profile_type: Task.profile_type_owner, complete_date: Time.now)
    end

    it 'redirects to login if unauthenticated' do
      post url
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'shows list of completed tasks' do
      sign_in user_one
      post url, params: { filter: 'past', show: '' }, xhr: true
      expect(response.body).to include task_two.name
      expect(response.body).not_to include task_one.name
    end
  end

  context 'when POST /save' do
    let(:task_name) { Faker::Lorem.sentence }
    let!(:outcome_one) { create(:outcome) }

    let(:params) { { task: task_name, course_id: course_one.id, school_id: school_demo.id } }
    let(:url) { url_for(controller: 'task', action: :save) }

    it 'redirects to login if unauthenticated' do
      post url,
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'saves a new task' do
      sign_in user_one
      post url,
           params: params

      expect(response).to have_http_status(:ok)
      expect(response.body).to include task_name
    end

    it 'edits an existing task with outcomes' do
      sign_in user_one
      post url,
           params: {
             id: task_one.id,
             outcomes: outcome_one.id
           }

      expect(response).to have_http_status(:ok)
      expect(json_body['outcomes'][0]['id']).to eq(outcome_one.id)
    end
  end

  context 'when POST /task_complete' do
    let!(:outcome_one) { create(:outcome) }

    let(:params) { { task_id: task_one.id, check_val: 'true' } }
    let(:url) { url_for(controller: 'task', action: :task_complete) }

    it 'redirects to login if unauthenticated' do
      post url,
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'completes a task' do
      sign_in user_one
      post url,
           params: params
      expect(response).to have_http_status(:ok)
      expect(task_one.task_participants[0].status).to eq(Task.status_complete)
    end
  end

  context 'when POST /remove_tasks' do
    let(:params) { { task_id: task_one.id } }
    let(:url) { url_for(controller: 'task', action: :remove_tasks) }
    let!(:user_two) { create(:user, default_school: school_demo) }
    let!(:profile_two) { create(:profile, user: user_two, school: school_demo) }

    before do
      create(:task_participant, task: task_one, profile: profile_two, profile_type: Task.profile_type_member)
    end

    it 'redirects to login if unauthenticated' do
      post url,
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'removes a task' do
      sign_in user_one
      post url,
           params: params
      expect(response).to have_http_status(:ok)
      expect(json_body['status']).to be(true)

      task_one.reload
      expect(task_one.archived).to be(true)
    end
  end

  context 'when POST /outcome_unchecked' do
    let!(:outcome_one) { create(:outcome) }
    let!(:outcome_task_one) { create(:outcome_task, task: task_one, outcome: outcome_one) }
    let(:params) { { task_id: task_one.id, outcome_id: outcome_one.id } }
    let(:url) { url_for(controller: 'task', action: :outcome_unchecked) }

    before do
    end

    it 'redirects to login if unauthenticated' do
      post url,
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'unchecks an outcome' do
      sign_in user_one
      post url,
           params: params
      expect(response).to have_http_status(:ok)
      expect(json_body['status']).to be(true)
      expect { outcome_task_one.reload }.to raise_exception ActiveRecord::RecordNotFound
    end
  end
end
