# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Wardrobes' do
  let!(:user_one) { User.first }
  let!(:wardrobe_one) { Wardrobe.first }
  let!(:wardrobe_item_one) { WardrobeItem.first }

  context 'when GET /index' do
    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'wardrobe', action: :index)
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders wardrobe page' do
      sign_in user_one
      get url_for(controller: 'wardrobe', action: :index),
          xhr: true
      expect(response.body).to render_template 'wardrobe/_list'
    end
  end

  context 'when GET /show' do
    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'wardrobe', action: :show),
          params: { wardrobe: wardrobe_one.id, id: wardrobe_item_one.id }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders wardrobe page' do
      sign_in user_one
      get url_for(controller: 'wardrobe', action: :show),
          xhr: true,
          params: { wardrobe: wardrobe_one.id, id: wardrobe_item_one.id }
      expect(response.body).to render_template 'wardrobe/_form'
      expect(response.body).to include wardrobe_item_one.name
    end
  end
end
