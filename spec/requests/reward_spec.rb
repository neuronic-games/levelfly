# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reward', type: :request do
  before(:all) do
    @user = User.first
    @school_demo = School.find_by!(handle: 'demo')
    @profile = @user.profiles.first

    @reward = FactoryBot.create(:reward, target_type: 'wardrobe', target_id: Wardrobe.second.id)
  end

  context 'GET /index' do
    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'reward', action: :index)
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders game list' do
      sign_in @user

      get url_for(controller: 'reward', action: :index)
      expect(response.body).to render_template 'reward/_list'
      expect(response.body).to include @reward.xp.to_s
    end
  end
end
