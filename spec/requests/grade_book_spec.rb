# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Grade books' do
  let!(:user_one) { User.first }
  let!(:school_demo) { School.find_by!(handle: 'demo') }
  let!(:profile_one)  { user_one.profiles.first }
  let!(:course_one) { create(:course, school: school_demo, owner: profile_one) }

  context 'when GET /index' do
    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'grade_book', action: :index)
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders index page' do
      sign_in user_one
      get url_for(controller: 'grade_book', action: :index),
          xhr: true
      expect(response.body).to render_template 'grade_book/_load_data'
      expect(response.body).to include course_one.name

      # TODO: check that an archived course is correctly shown
    end
  end

  context 'when POST /filter' do
    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'grade_book', action: :filter)
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders filter page' do
      sign_in user_one
      post url_for(controller: 'grade_book', action: :filter),
           xhr: true,
           params: { filter: 'past' }
      expect(response.body).to render_template 'grade_book/_load_data'
      expect(response.body).not_to include course_one.name
    end
  end

  context 'when POST /grading_complete' do
    it 'redirects to login if unauthenticated' do
      post url_for(controller: 'grade_book', action: :grading_complete),
           params: { id: course_one.id }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'finalizes grading' do
      sign_in user_one
      post url_for(controller: 'grade_book', action: :grading_complete),
           xhr: true,
           params: { id: course_one.id }

      expect(response.parsed_body['running']).to be true
    end
  end
end
