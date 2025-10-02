# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GameCenter' do
  let!(:game_one) { create(:game, school: school_demo) }
  let!(:feat) { create(:feat, game: game_one, profile: profile_one) }

  before do
    create(:game_school, game: game_one, school: school_demo)
  end

  context 'when GET /index' do
    let(:url) { url_for(controller: 'gamecenter', action: :index) }
    let(:params) { { profile_id: profile_one.id } }

    it 'redirects to login if unauthenticated' do
      get url, params: params

      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders index' do
      sign_in user_one

      get url, params: params

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
    let(:url) { url_for(controller: 'gamecenter', action: :get_rows) }
    let(:params) { { filter: 'gameboard' } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders game list' do
      sign_in user_one

      get url, params: params, xhr: true

      expect(response.body).to render_template 'gamecenter/_rows'
      expect(response.body).to include CGI.escapeHTML(game_one.name)

      game_two = create(:game, school: school_demo, archived: true)
      create(:game_school, game: game_two, school: school_demo)
      create(:feat, game: game_two, profile: profile_one)

      get url, params: { filter: 'archived' }, xhr: true

      expect(response.body).to render_template 'gamecenter/_rows'
      expect(response.body).not_to include CGI.escapeHTML(game_one.name)
      expect(response.body).to include CGI.escapeHTML(game_two.name)
    end
  end

  context 'when GET /achivements' do
    let!(:badge) { create(:badge, school_id: school_demo.id) }
    let!(:feat_badge) do
      create(:feat, progress_type: Feat.badge, progress: badge.id, game: game_one, profile: profile_one)
    end

    let(:url) { url_for(controller: 'gamecenter', action: :achivements) }
    let(:params) { { game_id: game_one.id } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders achievements partial' do
      sign_in user_one

      get url, params: params

      expect(response).to have_http_status :ok
      expect(response).to render_template 'gamecenter/_achivements'
      expect(response.body).to include badge.name
    end
  end

  context 'when GET /add_badge' do
    let(:url) { url_for(controller: 'gamecenter', action: :add_badge) }
    let(:params) { { game_id: game_one.id } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders add badge partial' do
      sign_in user_one

      get url, params: params

      expect(response).to have_http_status :ok
      expect(response).to render_template 'gamecenter/_add_game_badge'
    end
  end

  context 'when GET /add_game' do
    let(:url) { url_for(controller: 'gamecenter', action: :add_game) }

    it 'redirects to login if unauthenticated' do
      get url
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders add game partial' do
      sign_in user_one

      get url

      expect(response).to have_http_status :ok
      expect(response).to render_template 'gamecenter/_form'
    end
  end

  context 'when GET /all_badges' do
    let!(:badge) { create(:badge, school_id: school_demo.id, quest_id: game_one.id) }
    let!(:feat_badge) do
      create(:feat, progress_type: Feat.badge, progress: badge.id, game: game_one, profile: profile_one)
    end

    let(:url) { url_for(controller: 'gamecenter', action: :all_badges) }
    let(:params) { { game_id: game_one.id } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders all badges partial' do
      sign_in user_one

      get url, params: params

      expect(response).to have_http_status :ok
      expect(response).to render_template 'gamecenter/_all_badges'
      expect(response.body).to include badge.name
    end

    # TODO: Test that non-admin users can't see badges (see `gamecenter_write_access`)
  end

  context 'when GET /download' do
    let(:user_two) { create(:user, default_school: school_demo) }

    let(:url) { url_for(controller: 'gamecenter', action: :download) }
    let(:params) { { game_id: game_one.id } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders download partial' do
      # NOTE: Logging in as second user here because first user sees edit page
      sign_in user_two

      get url, params: params

      expect(response).to have_http_status :ok
      expect(response).to render_template 'gamecenter/_download'
      expect(response.body).to include game_one.download_links['linux']
    end
  end

  context 'when GET /edit_badge' do
    let(:user_two) { create(:user, default_school: school_demo) }
    let(:url) { url_for(controller: 'gamecenter', action: :edit_badge) }
    let(:params) { { game_id: game_one.id, id: 1 } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in gamecenter_controller.rb'
      sign_in user_two

      get url, params: params

      expect(response).to have_http_status :unauthorized
    end

    it 'renders edit badge partial' do
      sign_in user_one

      get url, params: params

      expect(response).to have_http_status :ok
      expect(response).to render_template 'gamecenter/_add_game_badge'
    end
  end

  context 'when GET /edit_game' do
    let(:user_two) { create(:user, default_school: school_demo) }
    let(:url) { url_for(controller: 'gamecenter', action: :edit_game) }
    let(:params) { { id: game_one.id } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'denies unrelated user' do
      skip 'Need to verify if this is intended behaviour, see note in gamecenter_controller.rb'
      sign_in user_two

      get url, params: params

      expect(response).to have_http_status :unauthorized
    end

    it 'renders edit game partial' do
      sign_in user_one

      get url, params: params

      expect(response).to have_http_status :ok
      expect(response).to render_template 'gamecenter/_form'
    end
  end

  context 'when GET /game_details' do
    let(:url) { url_for(controller: 'gamecenter', action: :game_details) }
    let(:params) { { id: game_one.id } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders game details partial' do
      sign_in user_one

      get url, params: params

      expect(response).to have_http_status :ok
      expect(response).to render_template 'gamecenter/_game_details'
      expect(response.body).to include game_one.name
    end
  end

  context 'when GET /leaderboard' do
    let(:profile_xp_less) { create(:profile, xp: 1) }
    let(:profile_xp_more) { create(:profile, xp: 2) }

    let(:url) { url_for(controller: 'gamecenter', action: :leaderboard) }
    let(:params) { { game_id: game_one.id } }

    before do
      create(:feat, game: game_one, profile: profile_xp_less)
      create(:feat, game: game_one, profile: profile_xp_more)
    end

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders leaderboard partial' do
      sign_in user_one

      get url, params: params

      expect(response).to have_http_status :ok
      expect(response).to render_template 'gamecenter/_leader_board'
      # Check leaderboard is in order
      profiles = assigns(:profiles)
      expect(profiles[0].full_name).to eq(profile_xp_more.full_name)
      expect(profiles[1].full_name).to eq(profile_xp_less.full_name)
      expect(profiles[2].full_name).to eq(profile_one.full_name)
      # TODO: Check `rank` property also?
      # TODO: Code golf
    end
  end

  context 'when GET /support' do
    let(:url) { url_for(controller: 'gamecenter', action: :support) }
    let(:params) { { game_id: game_one.id } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders support interface' do
      sign_in user_one

      get url, params: params, xhr: true

      expect(response).to have_http_status :ok
      expect(response).to render_template 'course/_form'

      # TODO: Test some of the context variables
    end
  end

  context 'when GET /view_game' do
    let(:url) { url_for(controller: 'gamecenter', action: :view_game) }
    let(:params) { { id: game_one.id } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders view game partial' do
      sign_in user_one

      get url, params: params

      expect(response).to have_http_status :ok
      expect(response).to render_template 'gamecenter/_form'
      expect(assigns[:game].id).to eq(game_one.id)
      # TODO: Could check support email address?
    end
  end

  context 'when GET /view_game_stats' do
    let(:url) { url_for(controller: 'gamecenter', action: :view_game_stats) }
    let(:params) { { game_id: game_one.id } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'renders game stats partial' do
      sign_in user_one

      get url, params: params

      expect(response).to have_http_status :ok
      expect(response).to render_template 'gamecenter/_game_stats'
      # TODO: Check contents of @feats, @outcome_list, @badges
    end
  end

  context 'when POST /save_badge' do
    let(:url) { url_for(controller: 'gamecenter', action: :save_badge) }
    # TODO: Maybe use attributes_for
    let(:params) do
      {
        game_id: game_one.id, name: Faker::Lorem.sentence(word_count: 2), descr: Faker::Lorem.sentence(word_count: 2)
      }
    end

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'creates new badge' do
      sign_in user_one

      post url, params: params

      expect(response).to have_http_status :ok
      expect(json_body['message']).to eq('Badge Created')
      # NOTE: There is one badge created in db/seed.rb
      expect(Badge.count).to eq(2)
      expect(assigns[:badge].name).to eq(params[:name])
    end

    it 'updates existing badge' do
      sign_in user_one

      badge = create(:badge, school_id: school_demo.id)
      expect(Badge.count).to eq(2)

      post url, params: params.merge!({ badge_id: badge.id })

      expect(response).to have_http_status :ok
      expect(json_body['message']).to eq('Badge Updated')
      expect(Badge.count).to eq(2)
    end
  end

  context 'when POST /save_game' do
    let(:url) { url_for(controller: 'gamecenter', action: :save_game) }
    let(:params) do
      {
        game: attributes_for(:game)
      }
    end

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'saves new game' do
      sign_in user_one

      post url, params: params, xhr: true

      expect(response).to have_http_status :ok
      expect(Game.count).to eq(2)
      expect(assigns[:game].name).to eq(params[:game][:name])
    end
  end

  # NOTE: PATCH is currently handled the same as PUT
  context 'when PUT /update_game' do
    let(:url) { url_for(controller: 'gamecenter', action: :update_game) }
    let(:params) { { game: attributes_for(:game), id: game_one.id } }

    it 'redirects to login if unauthenticated' do
      put url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'updates game' do
      sign_in user_one

      put url, params: params

      expect(response).to have_http_status :ok
      game_one.reload
      expect(game_one.name).to eq(params[:game][:name])
    end
  end

  context 'when GET /add_checkpoint' do
    let(:url) { url_for(controller: 'gamecenter', action: :add_checkpoint, handle: game_one.handle) }
    let(:params) { { checkpoint: 'test_checkpoint' } }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'saves checkpoint' do
      sign_in user_one

      get url, params: params

      expect(response).to have_http_status :ok
      expect(json_body['status']).to eq(Gamecenter::SUCCESS)
      expect(Checkpoint.count).to eq(1)
      expect(Checkpoint.first.game).to eq(game_one)
    end
  end

  context 'when GET /add_game_badge', skip: 'Unused controller method?' do
    let(:url) { url_for(controller: 'gamecenter', action: :add_game_badge, handle: game_one.handle) }
    let(:params) { attributes_for(:badge).merge!({ handle: game_one.handle }) }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'creates game badge' do
      sign_in user_one

      get url, params: params

      expect(response).to have_http_status :ok
      # TODO: Check response
    end
  end

  context 'when GET /add_progress' do
    let(:url) { url_for(controller: 'gamecenter', action: :add_progress, handle: game_one.handle) }
    let(:params) { { progress: 10, progress_type: Feat.xp } }

    it 'records progress' do
      sign_in user_one

      get url, params: params

      expect(response).to have_http_status :ok
      expect(json_body['status']).to eq(Gamecenter::SUCCESS)
      expect(json_body['message']).to include 'Progress recorded for'
      expect(json_body['message']).to include game_one.name
    end
  end

  context 'when GET /get_checkpoint' do
    let!(:checkpoint) { create(:checkpoint, game: game_one, profile: profile_one) }
    let(:url) { url_for(controller: 'gamecenter', action: :get_checkpoint, handle: game_one.handle) }

    it 'redirects to login if unauthenticated' do
      get url
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'gets checkpoint' do
      sign_in user_one

      get url

      expect(response).to have_http_status :ok
      expect(json_body['status']).to eq(Gamecenter::SUCCESS)
      expect(json_body['checkpoint']).to eq(checkpoint.checkpoint)
    end
  end

  context 'when GET /get_rewards' do
    let!(:badge) { create(:badge, school_id: school_demo.id, quest_id: game_one.id) }
    let!(:outcome) { create(:outcome, school_id: school_demo.id, game_id: game_one.id) }

    let(:url) { url_for(controller: 'gamecenter', action: :get_rewards, handle: game_one.handle) }

    it 'gets rewards without authentication' do
      get url

      expect(response).to have_http_status :ok
      expect(json_body['status']).to eq(Gamecenter::SUCCESS)
      expect(json_body['badges'][0]).to eq(badge.name)
      expect(json_body['outcomes'][0]).to eq(outcome.name)
    end
  end

  context 'when GET /get_top_users' do
    let!(:feat_score) { create(:feat, progress_type: Feat.score, progress: 50, game_id: game_one.id, profile: profile_one) }
    let(:url) { url_for(controller: 'gamecenter', action: :get_top_users, handle: game_one.handle) }

    it 'gets top users without authentication' do
      get url

      expect(response).to have_http_status :ok
      expect(json_body['status']).to eq(Gamecenter::SUCCESS)
      expect(json_body['message']).to eq('1 score records found.')
      feat_data = json_body['all_score'][0]
      expect(feat_data[0]).to eq(profile_one.id)
      expect(feat_data[1]).to eq(feat_score.progress)
      expect(feat_data[2]).to eq(profile_one.full_name)
    end
  end

  context 'when GET /list_leaders' do
    let!(:game_score_leader) { create(:game_score_leader, game: game_one, profile: profile_one, full_name: profile_one.full_name, score: 5) }
    let(:url) { url_for(controller: 'gamecenter', action: :list_leaders, handle: game_one.handle) }

    it 'redirects to login if unauthenticated' do
      get url
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'lists leaders' do
      sign_in user_one

      get url, xhr: true

      expect(response).to have_http_status :ok
      expect(assigns[:leaders][0]).to eq(game_score_leader)
      expect(response.body).to include game_score_leader.full_name
    end
  end

  context 'when GET /list_progress' do
    let(:url) { url_for(controller: 'gamecenter', action: :list_progress, handle: game_one.handle) }
    let(:params) { { count: 10, profile_id: profile_one.id } }
    let!(:feat) { create(:feat, game: game_one, profile: profile_one) }

    it 'redirects to login if unauthenticated' do
      get url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'lists progress' do
      sign_in user_one

      get url, params: params, xhr: true

      expect(response).to have_http_status :ok
      expect(response.body).to include profile_one.full_name
    end
  end

  # NOTE: GET currently uses the same code path as POST
  context 'when POST /export_game_csv' do
    let(:url) { url_for(controller: 'gamecenter', action: :export_game_csv, game_id: game_one.id) }
    let(:params) { { profile_id: profile_one.id } }

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'exports CSV' do
      sign_in user_one

      post url, params: params

      expect(response).to have_http_status :ok
      # FIXME: Probably 'text/csv'?
      expect(response.content_type).to include('test/csv')

      row = CSV.parse(response.body, headers: true)[0]

      expect(row['Player']).to eq(profile_one.full_name)
      # TODO: Test more columns
    end
  end

  # NOTE: GET currently uses the same code path as POST
  context 'when POST /export_game_activity_csv' do
    let(:url) { url_for(controller: 'gamecenter', action: :export_game_activity_csv, game_id: game_one.id) }
    let(:params) { { profile_id: profile_one.id } }

    before do
      create(:feat, progress_type: Feat.login, game_id: game_one.id, profile: profile_one)
      create(:feat, progress_type: Feat.score, progress: 50, game_id: game_one.id, profile: profile_one)
      create(:feat, progress_type: Feat.duration, progress: 50, game_id: game_one.id, profile: profile_one)
    end

    it 'redirects to login if unauthenticated' do
      post url, params: params
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'exports activity CSV' do
      sign_in user_one

      post url, params: params

      expect(response).to have_http_status :ok
      # FIXME: Probably 'text/csv'?
      expect(response.content_type).to include('test/csv')

      row = CSV.parse(response.body, headers: true)[0]

      expect(row['Score']).to eq('50')
      expect(row['Duration (sec)']).to eq('50')
    end
  end

  # NOTE: GET currently uses the same code path as POST
  context 'when POST /show' do
    let(:url) { url_for(controller: 'gamecenter', action: :show, id: game_one.id) }

    it 'shows game without authentication' do
      post url

      expect(response).to have_http_status :ok
      expect(response).to render_template layout: 'public'

      # TODO: check @download_link, @guide_link, @game, @outcomes
    end
  end
end
