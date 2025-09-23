# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Wardrobes', type: :request do
  before(:all) do
    @user = User.first
    @school_demo = School.find_by!(handle: 'demo')
    @profile = @user.profiles.first
  end

  context 'GET /index' do
    it 'should redirect to login if unauthenticated' do
      get url_for(controller: 'wardrobe', action: :index)
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render wardrobe page' do
      sign_in @user
      get url_for(controller: 'wardrobe', action: :index),
          xhr: true
      expect(response.body).to render_template 'wardrobe/_list'
    end
  end
end
