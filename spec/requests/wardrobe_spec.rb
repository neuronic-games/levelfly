# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Wardrobes', type: :request do
  before(:all) do
    @user = User.first
    @school_demo = School.find_by!(handle: 'demo')
    @profile = @user.profiles.first

    @wardrobe = Wardrobe.first
    @wardrobe_item = WardrobeItem.first
  end

  context 'GET /index' do
    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'wardrobe', action: :index)
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders wardrobe page' do
      sign_in @user
      get url_for(controller: 'wardrobe', action: :index),
          xhr: true
      expect(response.body).to render_template 'wardrobe/_list'
    end
  end

  context 'GET /show' do
    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'wardrobe', action: :show),
          params: { wardrobe: @wardrobe.id, id: @wardrobe_item.id }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders wardrobe page' do
      sign_in @user
      get url_for(controller: 'wardrobe', action: :show),
          xhr: true,
          params: { wardrobe: @wardrobe.id, id: @wardrobe_item.id }
      expect(response.body).to render_template 'wardrobe/_form'
      expect(response.body).to include @wardrobe_item.name
    end
  end
end
