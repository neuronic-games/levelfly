# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Courses', type: :request do
  before(:all) do
    @user = User.first
    @school_demo = School.find_by!(handle: 'demo')
    @profile = @user.profiles.first

    # NOTE: Reluctantly, this seems better than using let or let!:
    # * with let, the participant is not created unless directly referenced in each test case, so index doesn't show any courses
    # * with let!, a new course and participant are created for each test case
    @course = FactoryBot.create(:course, school: @school_demo, owner: @profile)
    @participant = FactoryBot.create(:participant, target: @course, target_type: 'Course', profile: @profile,
                                                    profile_type: 'M')
    @user_two = FactoryBot.create(:user, default_school: @school_demo)
    @profile_two = FactoryBot.create(:profile, user: @user_two, school: @school_demo)
  end

  after(:all) do
    @user_two.delete
    @participant.delete
    @profile_two.delete
    @course.delete
  end

  context 'GET /Index' do
    it 'should redirect to login if unauthenticated' do
      get url_for controller: 'course', action: :index
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render index page' do
      sign_in @user
      get url_for controller: 'course', action: :index,
                  params: { section_type: 'C' }
      expect(response.body).to include @course.name

      get url_for controller: 'course', action: :index,
                  params: { section_type: 'C' },
                  xhr: true
      expect(response.body).to include @course.name

      get url_for controller: 'course', action: :index,
                  params: { section_type: 'C', search_text: @course.code }
      expect(response.body).to include @course.name

      get url_for controller: 'course', action: :index,
                  params: { section_type: 'C', search_text: 'xxxxxxxxxxxxx' }
      expect(response.body).not_to include @course.name
    end
  end

  context 'GET /new' do
    it 'should redirect to login if unauthenticated' do
      get url_for(controller: 'course', action: :new),
          params: { section_type: 'C' }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render new page' do
      # NOTE: This doesn't test the non-xhr code path in the controller, because it seems to return an authentication error
      sign_in @user

      get url_for(controller: 'course', action: :new),
          params: { section_type: 'C' },
          xhr: true,
          as: :html
      expect(response.body).to include 'Click the Add Outcome button'
    end
  end

  context 'GET /show' do
    it 'should redirect to login if unauthenticated' do
      get url_for(controller: 'course', action: :show, id: @course.id),
          params: { id: @course.id, section_type: 'C' },
          as: :html
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render show page' do
      sign_in @user
      get url_for(controller: 'course', action: :show, id: @course.id),
          params: { section_type: 'C' },
          xhr: true,
          as: :html
      expect(response.body).to include @course.name
    end
  end

  context 'GET /view_setup' do
    it 'should redirect to login if unauthenticated' do
      get url_for controller: 'course', action: :view_setup,
                  params: { id: @course.id },
                  as: :html
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render view_setup page' do
      sign_in @user
      get url_for controller: 'course', action: :view_setup,
                  params: { id: @course.id },
                  as: :html
      expect(response).to render_template 'course/_setup'
    end
  end

  context 'POST /save' do
    it 'should redirect to login if unauthenticated' do
      post url_for controller: 'course', action: :save,
                   params: FactoryBot.attributes_for(:course),
                   as: :html
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should save course' do
      sign_in @user

      course_two = FactoryBot.create(:course, school: School.find_by!(handle: 'demo'))
      # NOTE: deliberately don't create a participant here, to test the auto-creation in the controller method

      new_name = Faker::Educator.subject

      course_params = course_two.attributes
      # TODO: possible code golf here, I forgot for a while that the form param is called "course" not "name"
      course_params['course'] = new_name

      # TODO: also check for other discrepancies between model fields and form fields

      # TODO: test :file param
      # TODO: test :categories param

      post url_for controller: 'course', action: :save,
                   params: course_params,
                   as: :html
      expect(Course.find(course_two.id).name).to eq(new_name)
    end
  end

  context 'POST /get_participants' do
    it 'should redirect to login if unauthenticated' do
      post url_for(controller: 'course', action: :get_participants),
           params: { school_id: @course.school.id, search_text: User.first.email }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should fail on self' do
      sign_in @user

      post url_for(controller: 'course', action: :get_participants),
           params: { school_id: @course.school.id, search_text: User.first.email }

      expect(response.body).to eq('you cant add yourself')
    end

    it 'should get participants' do
      sign_in @user

      participant = FactoryBot.create(:participant, target: @course, target_type: 'Course', profile: @profile_two,
                                       profile_type: 'S')

      post url_for(controller: 'course', action: :get_participants),
           params: { school_id: @course.school.id, search_text: @user_two.email }

      expect(response.body).to include @profile_two.full_name

      post url_for(controller: 'course', action: :get_participants),
           params: { school_id: @course.school.id, search_text: @profile_two.full_name }

      expect(response.body).to include @profile_two.full_name

      # TODO: Should this be necessary?
      participant.delete
    end
  end

  context 'POST /add_participant' do
    # TODO: Test inviting a non-existant user
    # TODO: Test re-inviting an already-invited user
    it 'should redirect to login if unauthenticated' do
      post url_for(controller: 'course', action: :add_participant),
           params: { course_id: @course.id, section_type: 'C', email: @user_two.email }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should add participant' do
      sign_in @user

      post url_for(controller: 'course', action: :add_participant),
           params: { course_id: @course.id, section_type: 'C', email: @user_two.email }

      response_parsed = JSON.parse(response.body)

      expect(response_parsed['status']).to be true
      expect(response_parsed['already_added']).to be false
      expect(response_parsed['profiles'][0]['full_name']).to eq(@profile_two.full_name)

      # TODO: Should this be necessary?
      @profile_two.participants.first.delete
    end

    it 'should add already-added participant' do
      sign_in @user

      FactoryBot.create(:participant, target: @course, target_type: 'Course', profile: @profile_two,
                                       profile_type: 'S')

      post url_for(controller: 'course', action: :add_participant),
           params: { course_id: @course.id, section_type: 'C', email: @user_two.email }

      response_parsed = JSON.parse(response.body)

      expect(response_parsed['status']).to be false
      expect(response_parsed['already_added']).to be true
      expect(response_parsed['profiles'][0]['full_name']).to eq(@profile_two.full_name)
    end
  end
end
