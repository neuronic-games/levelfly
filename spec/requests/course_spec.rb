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
      get '/course/'
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render index page if authenticated' do
      sign_in User.first
      get '/course/',
          params: { section_type: 'C' }
      expect(response.body).to include @course.name

      get '/course/',
          params: { section_type: 'C' },
          xhr: true
      expect(response.body).to include @course.name
    end
  end

  context 'Get /new' do
    it 'should redirect to login if unauthenticated' do
      get '/course/new',
          params: { section_type: 'C' }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render new page if authenticated' do
      sign_in User.first
      get '/course/new',
          params: { section_type: 'C' },
          xhr: true,
          as: :html
      expect(response.body).to include 'Click the Add Outcome button'
    end
  end

  context 'Get /view_setup' do
    it 'should redirect to login if unauthenticated' do
      get '/course/view_setup',
          params: { id: @course.id },
          as: :html
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render view_setup page if authenticated' do
      sign_in User.first
      get '/course/view_setup',
          params: { id: @course.id },
          as: :html
      expect(response).to render_template 'course/_setup'
    end
  end
end
