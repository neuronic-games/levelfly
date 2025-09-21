# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Courses', type: :request do
  context 'Get /Index' do
    it 'should redirect to login if unauthenticated' do
      get '/course/'
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render index page if authenticated' do
      sign_in User.first
      get '/course/'
      expect(response).to render_template :index
    end
  end
end
