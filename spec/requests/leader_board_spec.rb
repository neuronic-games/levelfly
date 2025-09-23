# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Leader boards', type: :request do
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
      get url_for(controller: 'leader_board', action: :index)
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render index page' do
      sign_in @user
      get url_for(controller: 'leader_board', action: :index)
      expect(response.body).to render_template 'leader_board/_list'
    end
  end

  context 'GET /get_rows' do
    it 'should redirect to login if unauthenticated' do
      get url_for(controller: 'leader_board', action: :get_rows),
          params: { filter: 'school' }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render rows' do
      sign_in @user
      get url_for(controller: 'leader_board', action: :get_rows),
          params: { filter: 'school' }
      expect(response.body).to render_template 'leader_board/_rows'
      expect(response.body).to include @profile.full_name
    end
  end
end
