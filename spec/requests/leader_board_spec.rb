# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Leader boards', type: :request do
  before do
    create(:course, school: school_demo, owner: profile_one)
  end

  context 'when GET /index' do
    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'leader_board', action: :index)
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders index page' do
      sign_in user_one
      get url_for(controller: 'leader_board', action: :index)
      expect(response.body).to render_template 'leader_board/_list'
    end
  end

  context 'when GET /get_rows' do
    let(:params) { { filter: 'school' } }

    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'leader_board', action: :get_rows),
          params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders rows' do
      sign_in user_one
      get url_for(controller: 'leader_board', action: :get_rows),
          params: params
      expect(response.body).to render_template 'leader_board/_rows'
      expect(response.body).to include profile_one.full_name
    end
  end
end
