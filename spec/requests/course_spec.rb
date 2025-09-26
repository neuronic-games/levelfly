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
end
