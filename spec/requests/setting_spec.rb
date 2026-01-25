# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Settings', type: :request do
  let!(:setting_one) { create(:setting, target_id: school_demo.id) }

  context 'when GET /index' do
    it 'redirects to login if unauthenticated' do
      get url_for controller: 'setting', action: :index
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders settings list' do
      sign_in user_one
      get url_for controller: 'setting', action: :index
      expect(response.body).to include setting_one.name
    end
  end
end
