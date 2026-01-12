# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Courses' do
  let!(:course_one) { create(:course, school: school_demo, owner: profile_one) }
  let!(:user_two) { create(:user, default_school: school_demo) }
  let!(:profile_two) { create(:profile, user: user_two, school: school_demo) }

  let(:outcome) do
    outcome = create(:outcome, school_id: school_demo.id)
    course_one.outcomes << outcome
    return outcome
  end

  before do
    create(:participant, target: course_one, target_type: 'Course', profile: profile_one,
                         profile_type: 'M')
  end

  context 'when GET /Index' do
    let(:url) { url_for controller: 'course', action: :index }
    let(:params) { { section_type: 'C' } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders index page' do
      sign_in user_one
      get url, params: params
      expect(response.body).to include course_one.name
    end

    it 'renders index page as XHR' do
      sign_in user_one
      get url, params: params, xhr: true
      expect(response.body).to include course_one.name
    end

    it 'searches successfully by course code' do
      sign_in user_one
      get url, params: params.merge!({ search_text: course_one.code })
      expect(response.body).to include course_one.name
    end

    it "doesn't return unexpected results for a search" do
      sign_in user_one
      get url, params: params.merge!({ search_text: 'xxxxxxxxxxxxx' })
      expect(response.body).not_to include course_one.name
    end
  end

  context 'when GET /new' do
    let(:url) { url_for(controller: 'course', action: :new) }
    let(:params) { { section_type: 'C' } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders new page' do
      # NOTE: This doesn't test the non-xhr code path in the controller, because it seems to return
      # an authentication error
      sign_in user_one

      get url, params: params, xhr: true
      expect(response.body).to include 'Click the Add Outcome button'
    end
  end

  context 'when GET /show' do
    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'course', action: :show, id: course_one.id),
          params: { id: course_one.id, section_type: 'C' }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders show page' do
      sign_in user_one
      get url_for(controller: 'course', action: :show, id: course_one.id),
          params: { section_type: 'C' },
          xhr: true
      expect(response.body).to include course_one.name
    end
  end

  context 'when POST /view_setup' do
    it 'redirects to login if unauthenticated' do
      get url_for controller: 'course', action: :view_setup,
                  params: { id: course_one.id }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders view_setup page' do
      sign_in user_one
      get url_for controller: 'course', action: :view_setup,
                  params: { id: course_one.id }
      expect(response).to render_template 'course/_setup'
    end
  end

  context 'when POST /save' do
    it 'redirects to login if unauthenticated' do
      post url_for controller: 'course', action: :save,
                   params: attributes_for(:course)
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'saves course' do
      sign_in user_one

      course_two = create(:course, school: School.find_by!(handle: 'demo'))
      # NOTE: deliberately don't create a participant here, to test the auto-creation in the controller method

      new_name = Faker::Educator.subject

      # TODO: also check for other discrepancies between model fields and form fields

      # TODO: test :file param
      # TODO: test :categories param

      post url_for(controller: 'course', action: :save),
           params: course_two.attributes.merge({ course: new_name })
      expect(Course.find(course_two.id).name).to eq(new_name)
    end
  end

  context 'when POST /get_participants' do
    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :get_participants),
           params: { school_id: course_one.school.id, search_text: User.first.email }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'fails on self' do
      sign_in user_one

      post url_for(controller: 'course', action: :get_participants),
           params: { school_id: course_one.school.id, search_text: User.first.email }

      expect(response.body).to eq('you cant add yourself')
    end

    it 'gets participants by email' do
      sign_in user_one

      create(:participant, target: course_one, target_type: 'Course', profile: profile_two,
                           profile_type: 'S')

      post url_for(controller: 'course', action: :get_participants),
           params: { school_id: course_one.school.id, search_text: user_two.email }

      expect(response.body).to include CGI.escapeHTML(profile_two.full_name)
    end

    it 'gets participants by name' do
      sign_in user_one

      create(:participant, target: course_one, target_type: 'Course', profile: profile_two,
                           profile_type: 'S')

      post url_for(controller: 'course', action: :get_participants),
           params: { school_id: course_one.school.id, search_text: profile_two.full_name }

      expect(response.body).to include CGI.escapeHTML(profile_two.full_name)
    end
  end

  context 'when POST /add_participant' do
    # TODO: Test inviting a non-existant user
    # TODO: Test re-inviting an already-invited user
    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :add_participant),
           params: { course_id: course_one.id, section_type: 'C', email: user_two.email }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'adds participant' do
      sign_in user_one

      post url_for(controller: 'course', action: :add_participant),
           params: { course_id: course_one.id, section_type: 'C', email: user_two.email }

      expect(json_body['status']).to be true
      expect(json_body['already_added']).to be false
      expect(json_body['profiles'][0]['full_name']).to eq(profile_two.full_name)
    end

    it 'adds already-added participant' do
      sign_in user_one

      create(:participant, target: course_one, target_type: 'Course', profile: profile_two,
                           profile_type: 'S')

      post url_for(controller: 'course', action: :add_participant),
           params: { course_id: course_one.id, section_type: 'C', email: user_two.email }

      expect(json_body['status']).to be false
      expect(json_body['already_added']).to be true
      expect(json_body['profiles'][0]['full_name']).to eq(profile_two.full_name)
    end
  end

  context 'when POST /send_email_to_all_participants' do
    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :send_email_to_all_participants),
           params: { id: course_one.id, post_message: 'true', mail_msg: Faker::Lorem.sentence }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'emails participants' do
      Delayed::Worker.delay_jobs = false

      sign_in user_one

      create(:participant, target: course_one, target_type: 'Course', profile: profile_two,
                           profile_type: 'S')
      create(:wall, parent: profile_one)

      message_text = Faker::Lorem.sentence

      post url_for(controller: 'course', action: :send_email_to_all_participants),
           params: { id: course_one.id, post_message: 'true', mail_msg: message_text }

      expect(json_body['status']).to be true

      expect(ActionMailer::Base.deliveries.length).to eq 2
      sent_message = ActionMailer::Base.deliveries.first
      expect(sent_message.recipients).to include user_one.email
      expect(sent_message.body.parts.first.to_s).to include message_text

      Delayed::Worker.delay_jobs = true
    end
  end

  context 'when POST /delete_participant' do
    let!(:participant_two) do
      create(:participant, target: course_one, target_type: 'Course', profile: profile_two,
                           profile_type: 'S')
    end

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :delete_participant),
           params: { course_id: course_one.id, participant_id: participant_two.id }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'deletes participant' do
      sign_in user_one

      post url_for(controller: 'course', action: :delete_participant),
           params: { course_id: course_one.id, profile_id: profile_two.id }

      expect(json_body['status']).to be true

      expect { participant_two.reload }.to raise_exception ActiveRecord::RecordNotFound
    end
  end

  context 'when POST /remove_course_outcomes' do
    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :remove_course_outcomes),
           params: { course_id: course_one.id, outcomes: outcome.id }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'removes un-shared outcome' do
      sign_in user_one

      post url_for(controller: 'course', action: :remove_course_outcomes),
           params: { course_id: course_one.id, outcomes: outcome.id }

      expect(json_body['status']).to eq('true')

      expect { outcome.reload }.to raise_exception ActiveRecord::RecordNotFound
    end

    it 'removes shared outcome' do
      sign_in user_one

      outcome.shared = true
      outcome.save

      post url_for(controller: 'course', action: :remove_course_outcomes),
           params: { course_id: course_one.id, outcomes: outcome.id }

      expect(json_body['status']).to eq('true')

      expect(course_one.outcomes).not_to include outcome
      # Shouldn't delete the outcome completely
      expect { outcome.reload }.not_to raise_exception
    end
  end

  context 'when POST /remove_course_files' do
    let!(:attachment) do
      create(:attachment, school: school_demo, owner: profile_one, target: course_one, target_type: 'Course')
    end

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :remove_course_files),
           params: { files: attachment.id }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in course_controller.rb'
      sign_in user_two

      post url_for(controller: 'course', action: :remove_course_files),
           params: { files: attachment.id }

      expect(response.status).to eq(:forbidden)

      expect { attachment.reload }.not_to raise_exception ActiveRecord::RecordNotFound
    end

    it 'removes attachment' do
      sign_in user_one

      post url_for(controller: 'course', action: :remove_course_files),
           params: { files: attachment.id }

      expect(json_body['status']).to eq('true')

      expect { attachment.reload }.to raise_exception ActiveRecord::RecordNotFound
    end
  end

  context 'when POST /share_outcome' do
    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :share_outcome),
           params: { course_id: course_one.id, outcome_id: outcome.id }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in course_controller.rb'
      sign_in user_two

      post url_for(controller: 'course', action: :share_outcome),
           params: { course_id: course_one.id, outcome_id: outcome.id }

      expect(response.status).to eq(:forbidden)

      expect { attachment.reload }.not_to raise_exception ActiveRecord::RecordNotFound
    end

    it 'makes outcome shared' do
      sign_in user_one

      post url_for(controller: 'course', action: :share_outcome),
           params: { course_id: course_one.id, outcome_id: outcome.id }

      expect(json_body['status']).to eq('true')

      outcome.reload
      expect(outcome.shared).to be true
    end
  end

  context 'when POST /update_course_outcomes' do
    let(:outcome_new) { build(:outcome) }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :update_course_outcomes),
           params: { outcome_id: outcome.id, outcome: outcome_new.name, outcome_descr: outcome_new.descr }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in course_controller.rb'
      sign_in user_two

      post url_for(controller: 'course', action: :update_course_outcomes),
           params: { outcome_id: outcome.id, outcome: outcome_new.name, outcome_descr: outcome_new.descr }

      expect(response.status).to eq(:forbidden)

      outcome.reload
      expect(outcome.name).not_to eq(outcome_new.name)
    end

    it 'updates outcome' do
      sign_in user_one

      post url_for(controller: 'course', action: :update_course_outcomes),
           params: { outcome_id: outcome.id, outcome: outcome_new.name, outcome_descr: outcome_new.descr }

      expect(json_body['status']).to eq('true')

      outcome.reload
      expect(outcome.name).to eq(outcome_new.name)
    end
  end

  context 'when POST /update_course_categories' do
    let(:category) { create(:category, course: course_one, school_id: school_demo.id) }
    let(:category_new) { build(:category) }
    let(:params) do
      { category_id: category.id, category: category_new.name, category_value: category_new.percent_value }
    end

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :update_course_categories),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in course_controller.rb'
      sign_in user_two

      post url_for(controller: 'course', action: :update_course_categories),
           params: params

      expect(response.status).to eq(:forbidden)

      category.reload
      expect(category.name).not_to eq(category_new.name)
    end

    it 'updates category' do
      sign_in user_one

      post url_for(controller: 'course', action: :update_course_categories),
           params: params

      expect(json_body['status']).to eq('true')

      category.reload
      expect(category.name).to eq(category_new.name)
    end
  end

  context 'when POST /remove_course_categories' do
    let(:categories) { create_list(:category, 3, course: course_one, school_id: school_demo.id) }
    let(:params) { { categories: categories.pluck(:id).join(',') } }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :remove_course_categories),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in course_controller.rb'
      sign_in user_two

      post url_for(controller: 'course', action: :remove_course_categories),
           params: params

      expect(response.status).to eq(:forbidden)

      expect(Category.count).to eq(3)
    end

    it 'deletes categories' do
      sign_in user_one

      post url_for(controller: 'course', action: :remove_course_categories),
           params: params

      expect(json_body['status']).to eq('true')

      expect(Category.count).to eq(0)
    end
  end

  context 'when GET /view_member' do
    let(:params) { { id: course_one.id } }

    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'course', action: :view_member),
          params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'shows the course' do
      sign_in user_one

      create(:participant, target: course_one, target_type: 'Course', profile: profile_two,
                           profile_type: 'S')

      get url_for(controller: 'course', action: :view_member),
          params: params

      expect(response).to have_http_status(:ok)
      expect(response).to render_template 'course/_member_list'
      expect(response.body).to include(profile_two.full_name)
    end

    it 'only shows course participants' do
      sign_in user_one

      get url_for(controller: 'course', action: :view_member),
          params: params

      expect(response).to have_http_status(:ok)
      expect(response).to render_template 'course/_member_list'
      expect(response.body).not_to include(profile_two.full_name)
    end
  end

  context 'when POST /course_stats' do
    let(:params) { { id: course_one.id } }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :course_stats),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'shows course stats' do
      sign_in user_one

      post url_for(controller: 'course', action: :course_stats),
           params: params

      expect(response).to have_http_status(:ok)
      expect(response).to render_template 'course/_course_stats'
    end
  end

  context 'when POST /top_achivers' do
    let(:params) { { course_id: course_one.id, outcome_id: outcome.id } }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :top_achivers),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in course_controller.rb'
      sign_in user_two

      post url_for(controller: 'course', action: :top_achivers),
           params: params

      expect(response).to have_http_status(:forbidden)
    end

    it 'shows top achievers' do
      sign_in user_one

      post url_for(controller: 'course', action: :top_achivers),
           params: params

      expect(response).to have_http_status(:ok)
      expect(response).to render_template 'course/_top_achivers'
    end
  end

  context 'when POST /task_outcomes' do
    let(:task) { create(:task) }
    let(:params) { { task_id: task.id } }

    before do
      create(:outcome_task, outcome: outcome, task: task)
    end

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :task_outcomes),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in course_controller.rb'
      sign_in user_two

      post url_for(controller: 'course', action: :task_outcomes),
           params: params

      expect(response).to have_http_status(:forbidden)
    end

    it 'shows task outcomes' do
      sign_in user_one

      post url_for(controller: 'course', action: :task_outcomes),
           params: params

      expect(response).to have_http_status(:ok)
      expect(response).to render_template 'course/_task_outcomes'
      expect(response.body).to include outcome.name
    end
  end

  context 'when POST /set_archive' do
    let(:course_archived) { create(:course, school: school_demo, owner: profile_one, archived: true) }
    let(:params) { { id: course_one.id } }

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :set_archive),
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in course_controller.rb'
      sign_in user_two

      post url_for(controller: 'course', action: :set_archive),
           params: params

      expect(response).to have_http_status(:forbidden)
      course_one.reload
      expect(course_one.archived).to be false
    end

    it 'archives course' do
      sign_in user_one

      post url_for(controller: 'course', action: :set_archive),
           params: params

      expect(response).to have_http_status(:ok)
      expect(json_body['status']).to eq('Success')
      course_one.reload
      expect(course_one.archived).to be true

      course_archived.reload
      expect(course_archived.archived).to be true
    end

    it 'unarchives course' do
      sign_in user_one

      post url_for(controller: 'course', action: :set_archive),
           params: { id: course_archived.id, unarchive: true }

      expect(response).to have_http_status(:ok)
      expect(json_body['status']).to eq('Success')
      course_archived.reload
      expect(course_archived.archived).to be false

      expect(course_one.archived).to be false
    end
  end

  context 'when POST /removed' do
    let(:url) { url_for(controller: 'course', action: :removed) }
    let(:params) { { id: course_one.id } }

    it 'redirects to login if unauthenticated' do
      post url,
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'leaves course' do
      sign_in user_two

      participant_two = create(:participant, target: course_one, target_type: 'Course', profile: profile_two,
                                             profile_type: 'S')

      post url,
           params: params

      expect(response).to have_http_status(:ok)
      expect(json_body['status']).to be true

      expect { participant_two.reload }.to raise_exception ActiveRecord::RecordNotFound
    end

    it 'removes course' do
      sign_in user_one

      post url,
           params: params

      expect(response).to have_http_status(:ok)
      expect(json_body['status']).to be true
      course_one.reload
      expect(course_one.removed).to be true

      # TODO: Test that course tasks are archived
    end
  end

  context 'when POST /duplicate' do
    let(:url) { url_for(controller: 'course', action: :duplicate) }
    let(:params) { { id: course_one.id } }

    before do
      forum = create(:course, :forum, course_id: course_one.id, owner: profile_one)
      create(:participant, target: forum, target_type: 'Course', profile: profile_one,
                           profile_type: 'M')
      create(:message, target_id: course_one.id, target_type: course_one.parent_type, starred: true, profile: profile_one)
    end

    it 'redirects to login if unauthenticated' do
      post url,
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      sign_in user_two

      post url,
           params: params

      expect(response).to have_http_status(:unauthorized)
      expect(Course.count).to eq(2)
    end

    it 'duplicates course' do
      sign_in user_one

      Delayed::Worker.delay_jobs = false
      post url,
           params: params
      Delayed::Worker.delay_jobs = true

      expect(response).to have_http_status(:ok)
      course_one.reload
      duplicate = Course.find_by!(:name => "#{course_one.name} COPY")
      expect(duplicate).not_to be(nil)
      expect(Course.count).to eq(4)
      expect(Message.count).to eq(2)
      expect(course_one.messages.count).to eq(1)
      expect(duplicate.messages.count).to eq(1)
    end
  end

  context 'when GET /edit', skip: 'Missing controller method?' do
    let(:url) { url_for(controller: 'course', action: :edit) }
    let(:params) { { id: course_one.id } }

    it 'redirects to login if unauthenticated' do
      get url,
          params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders edit page' do
      sign_in user_one
      get url,
          params: params
      expect(response).to have_http_status(:ok)
      expect(response.body).to include course_one.name
    end
  end

  context 'when GET /export_activity_csv' do
    let(:url) { url_for(controller: 'course', action: :export_activity_csv, id: course_one.id) }
    let(:params) { { id: course_one.id } }

    it 'redirects to login if unauthenticated' do
      get url,
          params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'exports CSV data' do
      sign_in user_one
      get url,
          params: params
      expect(response).to have_http_status(:ok)
      # FIXME: Probably 'text/csv'?
      expect(response.content_type).to include 'test/csv'
    end
  end

  context 'when POST /show_course' do
    let(:url) { url_for(controller: 'course', action: :show_course) }
    let(:params) { { id: course_one.id, section_type: 'C', value: 1 } }

    it 'redirects to login if unauthenticated' do
      post url,
           params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders course show page' do
      sign_in user_one
      post url,
           params: params
      expect(response).to have_http_status(:ok)
      expect(response.body).to include course_one.name
    end
  end
end
