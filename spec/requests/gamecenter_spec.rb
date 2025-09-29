# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Gamecenter' do
  let!(:game_one) { create(:game, school: school_demo) }

  before do
    create(:game_school, game: game_one, school: school_demo)
    create(:feat, game: game_one, profile: profile_one)
  end

  context 'when GET /index' do
    let(:params) { { profile_id: profile_one.id } }

    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'gamecenter', action: :index),
          params: params

      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders index' do
      sign_in user_one

      get url_for(controller: 'gamecenter', action: :index),
          params: params

      expect(response).to have_http_status :ok
      expect(response).to render_template 'gamecenter/_list'
    end
  end

  context 'when GET /status' do
    it 'returns OK' do
      get url_for(controller: 'gamecenter', action: :status)
      expect(json_body['status']).to eq(Gamecenter::SUCCESS)
      expect(json_body['message']).to eq('All OK.')
    end
  end

  context 'when POST /authenticate' do
    let(:params) { { username: user_one.email, password: 'changeme' } }
    let(:url) { url_for(controller: 'gamecenter', action: :authenticate, handle: game_one.handle) }

    it 'fails with empty username and/or password' do
      get url,
          params: params.merge!({ username: '' })

      expect(json_body['status']).to eq(Gamecenter::FAILURE)
      expect(json_body['message']).to eq('Empty username/password.')
      expect(json_body['user']).to be_empty

      get url,
          params: params.merge!({ password: '' })

      expect(json_body['status']).to eq(Gamecenter::FAILURE)
      expect(json_body['message']).to eq('Empty username/password.')
      expect(json_body['user']).to be_empty
    end

    it 'fails with incorrect username and/or password' do
      get url,
          params: params.merge!({ password: 'swordfish' })
      expect(json_body['status']).to eq(Gamecenter::FAILURE)
      expect(json_body['message']).to be_empty
      expect(json_body['user']).to be_empty
    end

    it 'logs in existing user' do
      get url,
          params: params
      expect(json_body['status']).to eq(Gamecenter::SUCCESS)
      expect(json_body['message']).to eq("#{profile_one.full_name} signed in")
      # TODO: Check the actual user properties maybe
      expect(json_body['user']).not_to be_empty
    end

    it 'refuses to create new user for existing email' do
      get url,
          params: params.merge!({ new: 'true' })
      expect(json_body['status']).to eq(Gamecenter::FAILURE)
      expect(json_body['message']).to eq('User already exist.')
      expect(json_body['user']).to be_empty
      expect(User.count).to eq(1)
    end

    it 'creates a new user' do
      get url,
          params: params.merge!({ username: Faker::Internet.email, new: true })
      expect(json_body['status']).to eq(Gamecenter::SUCCESS)
      expect(json_body['message']).to eq(' signed in')
      expect(json_body['user']).not_to be_empty
      # TODO: Check the actual user properties maybe
      expect(User.count).to eq(2)
    end
  end

  context 'when GET /connect' do
    let(:url) { url_for(controller: 'gamecenter', action: :connect, handle: game_one.handle) }

    it 'connects to a game' do
      get url
      expect(response).to have_http_status :ok
      expect(json_body['status']).to eq(Gamecenter::SUCCESS)
      expect(json_body['message']).to eq("Connected to #{game_one.name}.")
      expect(json_body['game']['id']).to eq(game_one.id)
      expect(json_body['game']['name']).to eq(game_one.name)
    end

    # TODO: Test error on nonexistent game
  end

  context 'when GET /get_current_user' do
    let(:url) { url_for(controller: 'gamecenter', action: :get_current_user, handle: game_one.handle) }

    it 'fails if unauthenticated' do
      get url
      expect(response).to have_http_status :ok
      expect(json_body['status']).to eq(Gamecenter::FAILURE)
      expect(json_body['message']).to be_empty
      expect(json_body['user']).to be_empty
    end

    it 'returns current user info' do
      sign_in user_one
      get url
      expect(response).to have_http_status :ok
      expect(json_body['status']).to eq(Gamecenter::SUCCESS)
      expect(json_body['message']).to eq("#{profile_one.full_name} signed in.")
      expect(json_body['user']['alias']).to eq(profile_one.full_name)
    end
  end

  context 'when GET /get_active_dur' do
    let(:url) { url_for(controller: 'gamecenter', action: :get_active_dur, handle: game_one.handle) }
    let!(:feat) { create(:feat, game: game_one, profile: profile_one, progress_type: Feat.duration, progress: Faker::Number.between(from: 2.0, to: 100.0))}

    it 'redirects to login if unauthenticated' do
      get url
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'returns current user info' do
      sign_in user_one
      get url
      expect(response).to have_http_status :ok
      expect(json_body['status']).to eq(Gamecenter::SUCCESS)
      expect(json_body['message']).to eq("#{profile_one.full_name} signed in.")
      expect(json_body['active']).to eq(feat.progress)
    end
  end

  context 'when GET /get_rows' do
    let(:params) { { filter: 'gameboard' } }

    it 'redirects to login if unauthenticated' do
      get url_for(controller: 'gamecenter', action: :get_rows),
          params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders game list' do
      sign_in user_one

      get url_for(controller: 'gamecenter', action: :get_rows),
          xhr: true,
          params: params
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
