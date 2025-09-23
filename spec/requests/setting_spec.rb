# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Settings', type: :request do
  before(:all) do
    @user = User.first
    @school_demo = School.find_by!(handle: 'demo')
    @profile = @user.profiles.first

    @setting = FactoryBot.create(:setting, target_id: @school_demo.id)
  end

  after(:all) do
    @setting.delete
  end

  context 'GET /index' do
    it 'should redirect to login if unauthenticated' do
      get url_for controller: 'setting', action: :index
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render settings list' do
      sign_in @user
      get url_for controller: 'setting', action: :index
      expect(response.body).to include @setting.name
    end
  end
end
