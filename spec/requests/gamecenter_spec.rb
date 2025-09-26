# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Gamecenter' do
  let!(:user_one) { User.first }
  let!(:school_demo) { School.find_by!(handle: 'demo') }
  let!(:profile_one) { user_one.profiles.first }

  let!(:game_one) { create(:game, school: school_demo) }

  before do
    create(:game_school, game: game_one, school: school_demo)
    create(:feat, game: game_one, profile: profile_one)
  end

  # TODO: Test index

  context 'when GET /get_rows' do
    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'gamecenter', action: :get_rows),
          params: { filter: 'archived' }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders game list' do
      sign_in user_one

      get url_for(controller: 'gamecenter', action: :get_rows),
          xhr: true,
          params: { filter: 'gameboard' }
      expect(response.body).to render_template 'gamecenter/_rows'
      expect(response.body).to include CGI.escapeHTML(game_one.name)

      game_two = create(:game, school: school_demo, archived: true)
      create(:game_school, game: game_two, school: school_demo)
      create(:feat, game: game_two, profile: profile_one)

      get url_for(controller: 'gamecenter', action: :get_rows),
          xhr: true,
          params: { filter: 'archived' }
      expect(response.body).to render_template 'gamecenter/_rows'
      expect(response.body).not_to include CGI.escapeHTML(game_one.name)
      expect(response.body).to include CGI.escapeHTML(game_two.name)
    end
  end
end
