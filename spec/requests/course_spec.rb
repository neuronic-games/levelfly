# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Courses', type: :request do
  before(:all) do
    # NOTE: Reluctantly, this seems better than using let or let!:
    # * with let, the participant is not created unless directly referenced in each test case, so index doesn't show any courses
    # * with let!, a new course and participant are created for each test case
    @course = FactoryGirl.create(:course, school: School.find_by!(handle: 'demo'))
    @participant = FactoryGirl.create(:participant, target: @course, target_type: 'Course', profile: User.first.profiles.first,
                                                    profile_type: 'M')
  end

  context 'Get /Index' do
    it 'should redirect to login if unauthenticated' do
      get url_for controller: 'course', action: :index
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render index page if authenticated' do
      sign_in User.first
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

  context 'Get /new' do
    it 'should redirect to login if unauthenticated' do
      get url_for(controller: 'course', action: :new),
          params: { section_type: 'C' }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render new page if authenticated' do
      # NOTE: This doesn't test the non-xhr code path in the controller, because it seems to return an authentication error
      sign_in User.first

      get url_for(controller: 'course', action: :new),
          params: { section_type: 'C' },
          xhr: true,
          as: :html
      expect(response.body).to include 'Click the Add Outcome button'
    end
  end

  context 'Get /show' do
    it 'should redirect to login if unauthenticated' do
      get url_for(controller: 'course', action: :show, id: @course.id),
          params: { id: @course.id, section_type: 'C' },
          as: :html
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render show page if authenticated' do
      sign_in User.first
      get url_for(controller: 'course', action: :show, id: @course.id),
          params: { section_type: 'C' },
          xhr: true,
          as: :html
      expect(response.body).to include @course.name
    end
  end

  context 'Get /view_setup' do
    it 'should redirect to login if unauthenticated' do
      get url_for controller: 'course', action: :view_setup,
                  params: { id: @course.id },
                  as: :html
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render view_setup page if authenticated' do
      sign_in User.first
      get url_for controller: 'course', action: :view_setup,
                  params: { id: @course.id },
                  as: :html
      expect(response).to render_template 'course/_setup'
    end
  end

  context 'Post /save' do
    it 'should redirect to login if unauthenticated' do
      post url_for controller: 'course', action: :save,
                   params: FactoryGirl.attributes_for(:course).merge!({ id: @course.id }),
                   as: :html
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should save course if authenticated' do
      sign_in User.first

      course_two = FactoryGirl.create(:course, school: School.find_by!(handle: 'demo'))
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
end
