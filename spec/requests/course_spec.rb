# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Courses' do
  let!(:user_one) { User.first }
  let!(:school_demo) { School.find_by!(handle: 'demo') }
  let!(:profile_one)  { user_one.profiles.first }
  let!(:course_one) { create(:course, school: school_demo, owner: profile_one) }
  let!(:user_two) { create(:user, default_school: school_demo) }
  let!(:profile_two) { create(:profile, user: user_two, school: school_demo) }

  before do
    create(:participant, target: course_one, target_type: 'Course', profile: profile_one,
                         profile_type: 'M')
  end

  context 'when GET /Index' do
    it 'redirects to login if unauthenticated' do
      get url_for controller: 'course', action: :index
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders index page' do
      sign_in user_one
      get url_for controller: 'course', action: :index,
                  params: { section_type: 'C' }
      expect(response.body).to include course_one.name
    end

    it 'renders index page as XHR' do
      sign_in user_one
      get url_for controller: 'course', action: :index,
                  params: { section_type: 'C' },
                  xhr: true
      expect(response.body).to include course_one.name
    end

    it 'searches successfully by course code' do
      sign_in user_one
      get url_for controller: 'course', action: :index,
                  params: { section_type: 'C', search_text: course_one.code }
      expect(response.body).to include course_one.name
    end

    it "doesn't return unexpected results for a search" do
      sign_in user_one
      get url_for controller: 'course', action: :index,
                  params: { section_type: 'C', search_text: 'xxxxxxxxxxxxx' }
      expect(response.body).not_to include course_one.name
    end
  end

  context 'when GET /new' do
    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'course', action: :new),
          params: { section_type: 'C' }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders new page' do
      # NOTE: This doesn't test the non-xhr code path in the controller, because it seems to return
      # an authentication error
      sign_in user_one

      get url_for(controller: 'course', action: :new),
          params: { section_type: 'C' },
          xhr: true
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

  context 'when GET /view_setup' do
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
                   params: FactoryBot.attributes_for(:course)
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

      response_parsed = JSON.parse(response.body)

      expect(response_parsed['status']).to be true
      expect(response_parsed['already_added']).to be false
      expect(response_parsed['profiles'][0]['full_name']).to eq(profile_two.full_name)
    end

    it 'adds already-added participant' do
      sign_in user_one

      create(:participant, target: course_one, target_type: 'Course', profile: profile_two,
                           profile_type: 'S')

      post url_for(controller: 'course', action: :add_participant),
           params: { course_id: course_one.id, section_type: 'C', email: user_two.email }

      response_parsed = JSON.parse(response.body)

      expect(response_parsed['status']).to be false
      expect(response_parsed['already_added']).to be true
      expect(response_parsed['profiles'][0]['full_name']).to eq(profile_two.full_name)
    end
  end

  context 'when POST /send_email_to_all_participants' do
    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :send_email_to_all_participants),
           params: { id: course_one.id, post_message: 'true', mail_msg: Faker::Hipster.sentence }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'emails participants' do
      Delayed::Worker.delay_jobs = false

      sign_in user_one

      create(:participant, target: course_one, target_type: 'Course', profile: profile_two,
                           profile_type: 'S')
      create(:wall, parent: profile_one)

      message_text = Faker::Hipster.sentence

      post url_for(controller: 'course', action: :send_email_to_all_participants),
           params: { id: course_one.id, post_message: 'true', mail_msg: message_text }

      response_parsed = JSON.parse(response.body)

      expect(response_parsed['status']).to be true

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

      response_parsed = JSON.parse(response.body)

      expect(response_parsed['status']).to be true

      expect { participant_two.reload }.to raise_exception ActiveRecord::RecordNotFound
    end
  end

  context 'when POST /remove_course_outcomes' do
    let!(:outcome) do
      outcome = create(:outcome, school_id: school_demo.id)
      course_one.outcomes << outcome
      return outcome
    end

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :remove_course_outcomes),
           params: { course_id: course_one.id, outcomes: outcome.id }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'removes un-shared outcome' do
      sign_in user_one

      post url_for(controller: 'course', action: :remove_course_outcomes),
           params: { course_id: course_one.id, outcomes: outcome.id }

      response_parsed = JSON.parse(response.body)
      expect(response_parsed['status']).to eq('true')

      expect { outcome.reload }.to raise_exception ActiveRecord::RecordNotFound
    end

    it 'removes shared outcome' do
      sign_in user_one

      outcome.shared = true
      outcome.save

      post url_for(controller: 'course', action: :remove_course_outcomes),
           params: { course_id: course_one.id, outcomes: outcome.id }

      response_parsed = JSON.parse(response.body)
      expect(response_parsed['status']).to eq('true')

      expect(course_one.outcomes).to_not include outcome
      # Shouldn't delete the outcome completely
      expect{outcome.reload}.not_to raise_exception ActiveRecord::RecordNotFound
    end
  end

  context 'when POST /remove_course_files' do
    let!(:attachment) { create(:attachment, school: school_demo, owner: profile_one, target: course_one, target_type: 'Course' )}

    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'course', action: :remove_course_files),
        params: { files: attachment.id }
      expect(response).to redirect_to '/users/sign_in'
    end

    xit 'denies unrelated user' do
      # FIXME: See note in course_controller.rb
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

      response_parsed = JSON.parse(response.body)
      expect(response_parsed['status']).to eq('true')

      expect { attachment.reload }.to raise_exception ActiveRecord::RecordNotFound
    end
  end
end
