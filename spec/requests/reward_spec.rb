# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reward', type: :request do
  let!(:user_one) { User.first }

  let!(:reward_one) { FactoryBot.create(:reward, target_type: 'wardrobe', target_id: Wardrobe.second.id) }

  context 'when GET /index' do
    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'reward', action: :index)
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders game list' do
      sign_in user_one

      get url_for(controller: 'reward', action: :index)
      expect(response.body).to render_template 'reward/_list'
      expect(response.body).to include reward_one.xp.to_s
    end
  end
end
