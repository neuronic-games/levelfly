# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Grade books', type: :request do
  before(:all) do
    @user = User.first
    @school_demo = School.find_by!(handle: 'demo')
    @profile = @user.profiles.first

    @course = FactoryBot.create(:course, school: @school_demo, owner: @profile)
  end

  after(:all) do
    @course.delete
  end

  context 'GET /index' do
    it 'should redirect to login if unauthenticated' do
      get url_for(controller: 'grade_book', action: :index)
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render index page' do
      sign_in @user
      get url_for(controller: 'grade_book', action: :index),
          xhr: true
      expect(response.body).to render_template 'grade_book/_load_data'
      expect(response.body).to include @course.name

      # TODO: check that an archived course is correctly shown
    end
  end

  context 'POST /filter' do
    it 'should redirect to login if unauthenticated' do
      post url_for(controller: 'grade_book', action: :filter)
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render filter page' do
      sign_in @user
      post url_for(controller: 'grade_book', action: :filter),
           xhr: true,
           params: { filter: 'past' }
      expect(response.body).to render_template 'grade_book/_load_data'
      expect(response.body).not_to include @course.name
    end
  end

  context 'POST /grading_complete' do
    it 'should redirect to login if unauthenticated' do
      post url_for(controller: 'grade_book', action: :grading_complete),
           params: { id: @course.id }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should finalize grading' do
      sign_in @user
      post url_for(controller: 'grade_book', action: :grading_complete),
           xhr: true,
           params: { id: @course.id }

      response_parsed = JSON.parse(response.body)

      expect(response_parsed['running']).to be true
    end
  end
end
