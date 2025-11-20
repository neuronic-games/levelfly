# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Grade books' do
  let!(:course_one) { create(:course, school: school_demo, owner: profile_one) }

  context 'when GET /index' do
    let(:url) { url_for(controller: 'grade_book', action: :index) }

    it 'redirects to login if unauthenticated' do
      get url
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders index page' do
      sign_in user_one
      get url,
          xhr: true
      expect(response.body).to render_template 'grade_book/_load_data'
      expect(response.body).to include course_one.name
    end
  end

  context 'when POST /filter' do
    let(:params) { { filter: 'past' } }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'grade_book', action: :filter),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders filter page' do
      sign_in user_one
      post url_for(controller: 'grade_book', action: :filter),
           xhr: true,
           params: params
      expect(response.body).to render_template 'grade_book/_load_data'
      expect(response.body).not_to include course_one.name
    end
  end

  context 'when POST /grading_complete' do
    let(:params) { { id: course_one.id } }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'grade_book', action: :grading_complete),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'finalizes grading' do
      sign_in user_one
      post url_for(controller: 'grade_book', action: :grading_complete),
           xhr: true,
           params: params

      expect(response.parsed_body['running']).to be true
    end
  end

  context 'when GET /export_course_grade_csv' do
    let!(:course_sectioned) { create(:course, school: school_demo, owner: profile_one, section: 'Section') }
    let!(:user_two) { create(:user, default_school: school_demo) }
    let!(:profile_two) { create(:profile, user: user_two, school: school_demo) }
    let(:url) { url_for(controller: 'grade_book', action: :export_course_grade_csv, course_id: course_sectioned.id) }

    before do
      create(:participant, :course_student, target: course_one, profile: profile_two)
    end

    it 'redirects to login if unauthenticated' do
      get url
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'exports course grade CSV' do
      sign_in user_one
      get url
      expect(response).to have_http_status(:ok)
      # TODO: Probably 'text/csv'?
      expect(response.content_type).to include 'test/csv'
      # FIXME: Test response content
    end
  end

  context 'when GET /export_course_sectioned_csv' do
    let!(:course_sectioned) { create(:course, school: school_demo, owner: profile_one, section: 'Section') }
    let!(:outcome) { create(:outcome, school_id: school_demo.id) }

    let(:url) do
      url_for(controller: 'grade_book', action: :export_course_sectioned_csv, course_id: course_sectioned.id)
    end

    before do
      course_one.outcomes << outcome
    end

    it 'redirects to login if unauthenticated' do
      get url
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'exports sectioned course CSV' do
      sign_in user_one
      get url
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include 'text/csv'
      expect(response.body).to include course_sectioned.code
      expect(response.body).to include course_sectioned.section
    end
  end

  context 'when POST /course_outcomes' do
    let(:url) { url_for(controller: 'grade_book', action: :course_outcomes) }
    let(:params) { { course_id: course_one.id } }

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'loads course outcomes' do
      sign_in user_one
      post url, params: params
      expect(response).to have_http_status(:ok)
      # FIXME: Test response content
    end
  end

  context 'when POST /get_task' do
    let!(:task_one) { create(:task, school: school_demo, course: course_one) }
    let!(:user_two) { create(:user, default_school: school_demo) }
    let!(:profile_two) { create(:profile, user: user_two, school: school_demo) }

    let(:url) { url_for(controller: 'grade_book', action: :get_task) }
    let(:params) { { course_id: course_one.id, task_id: task_one.id } }

    before do
      create(:participant, :course_student, target: course_one, profile: profile_two)
    end

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'gets task data' do
      sign_in user_one
      post url, params: params, headers: { 'ACCEPT': 'application/json' }
      expect(response).to have_http_status(:ok)
      # FIXME: Test response content
    end
  end

  context 'when POST /grade_calculate' do
    let(:url) { url_for(controller: 'grade_book', action: :grade_calculate) }
    let(:params) { { course_id: course_one.id, characters: 'A,B,C', profile_id: profile_one.id } }

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'calculates grades' do
      sign_in user_one
      post url, params: params
      expect(response).to have_http_status(:ok)
      # FIXME: Test response content
    end
  end

  context 'when POST /load_achievements' do
    let!(:user_two) { create(:user, default_school: school_demo) }
    let!(:profile_two) { create(:profile, user: user_two, school: school_demo) }
    let!(:participant_student) { create(:participant, :course_student, target: course_one, profile: profile_two) }

    let(:url) { url_for(controller: 'grade_book', action: :load_achievements) }
    let(:params) { { course_id: course_one.id } }

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'loads achievements' do
      sign_in user_one
      post url, params: params
      expect(response).to have_http_status(:ok)
      expect(json_body['participant'].first['id']).to eq(participant_student.id)
      expect(json_body['count']).to eq(1)
    end
  end

  context 'when POST /load_notes' do
    let(:url) { url_for(controller: 'grade_book', action: :load_notes) }
    let(:params) { { course_id: course_one.id } }

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'loads notes' do
      sign_in user_one
      post url, params: params
      expect(response).to have_http_status(:ok)
      # FIXME: Test response content
    end
  end

  context 'when POST /load_outcomes' do
    let!(:outcome) { create(:outcome, school_id: school_demo.id) }
    let!(:participant_student) do
      create(:participant, :course_student, target: course_one,
                                            profile: create(:profile, user: create(:user, default_school: school_demo),
                                                                      school: school_demo))
    end

    let(:url) { url_for(controller: 'grade_book', action: :load_outcomes) }
    let(:params) { { course_id: course_one.id } }

    before do
      course_one.outcomes << outcome
    end

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'loads outcomes' do
      sign_in user_one
      post url, params: params
      expect(response).to have_http_status(:ok)
      expect(json_body['outcomes'].first).to eq(outcome.as_json)
      # TODO: Compare more properties
      expect(json_body['participants'].first['id']).to eq(participant_student.id)
      expect(json_body['count']).to eq(1)
    end
  end

  context 'when POST /load_task_setup' do
    let(:url) { url_for(controller: 'grade_book', action: :load_task_setup) }
    let!(:task_one) { create(:task, school: school_demo, course: course_one) }
    let(:params) { {  task_id: task_one.id } }

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'loads task setup' do
      sign_in user_one
      post url, params: params
      expect(response).to have_http_status(:ok)
      # FIXME: Test response content
    end
  end

  context 'when POST /outcomes_points' do
    let(:url) { url_for(controller: 'grade_book', action: :outcomes_points) }
    let(:params) { { course_id: course_one.id, profile_id: profile_one.id, average: '50' } }

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'calculates outcomes points' do
      sign_in user_one
      post url, params: params
      expect(response).to have_http_status(:ok)
      # FIXME: Test response content
    end
  end

  context 'when POST /save_notes' do
    let(:url) { url_for(controller: 'grade_book', action: :save_notes) }
    let(:params) { { course_id: course_one.id, notes: Faker::Lorem.paragraph } }

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'saves notes' do
      sign_in user_one
      post url, params: params
      expect(response).to have_http_status(:ok)
      # FIXME: Test response content
    end
  end

  context 'when POST /show_outcomes' do
    let!(:user_two) { create(:user, default_school: school_demo) }
    let(:url) { url_for(controller: 'grade_book', action: :show_outcomes) }
    let(:params) { { course_id: course_one.id, show: true } }

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in course_controller.rb'
      sign_in user_two
      post url, params: params
      expect(response).to have_http_status :unauthorized
    end

    it 'shows outcomes' do
      sign_in user_one
      post url, params: params
      expect(response).to have_http_status(:ok)
      # FIXME: Test response content
    end
  end

  context 'when POST /task_setup' do
    let!(:task_one) { create(:task, school: school_demo, course: course_one) }

    let(:url) { url_for(controller: 'grade_book', action: :task_setup) }
    let(:params) { { task_id: task_one.id } }

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'assigns outcomes' do
      sign_in user_one

      outcome = create(:outcome, school_id: school_demo.id)

      post url, params: params.merge({ outcomes: [outcome.id] })
      expect(response).to have_http_status(:ok)
      expect(json_body['status']).to be true
      expect(OutcomeTask.count).to eq(1)
      expect(OutcomeTask.first.task).to eq(task_one)
    end
  end
end
