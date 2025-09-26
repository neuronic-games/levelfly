# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Gamecenter', type: :request do
  before(:all) do
    @user = User.first
    @school_demo = School.find_by!(handle: 'demo')
    @profile = @user.profiles.first

    @game = FactoryBot.create(:game, school: @school_demo)
    @game_school = FactoryBot.create(:game_school, game: @game, school: @school_demo)
    @feat = FactoryBot.create(:feat, game: @game, profile: @profile)
  end

  # TODO: Test index

  context 'GET /get_rows' do
    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'gamecenter', action: :get_rows),
          params: { filter: 'archived' }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders game list' do
      sign_in @user

      get url_for(controller: 'gamecenter', action: :get_rows),
          xhr: true,
          params: { filter: 'gameboard' }
      expect(response.body).to render_template 'gamecenter/_rows'
      expect(response.body).to include CGI.escapeHTML(@game.name)

      game_two = FactoryBot.create(:game, school: @school_demo, archived: true)
      game_school_two = FactoryBot.create(:game_school, game: game_two, school: @school_demo)
      feat_two = FactoryBot.create(:feat, game: game_two, profile: @profile)

      get url_for(controller: 'gamecenter', action: :get_rows),
          xhr: true,
          params: { filter: 'archived' }
      expect(response.body).to render_template 'gamecenter/_rows'
      expect(response.body).not_to include CGI.escapeHTML(@game.name)
      expect(response.body).to include CGI.escapeHTML(game_two.name)
    end
  end
end
