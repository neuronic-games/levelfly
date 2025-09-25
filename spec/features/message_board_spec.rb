require 'rails_helper'
require_relative 'helpers/two_browsers'

describe 'send board message to friends', browser: true, js: true do
  before(:all) do
    @user = User.first
    @school_demo = School.find_by!(handle: 'demo')
    @profile = @user.profiles.first

    @user_two = FactoryBot.create(:user, default_school: @school_demo)
    @profile_two = FactoryBot.create(:profile, user: @user_two, school: @school_demo)
    
    # make users friends
    Participant.create(target: @profile_two, target_type: 'User', profile: @profile, profile_type: 'F')
    Participant.create(target: @profile, target_type: 'User', profile: @profile_two, profile_type: 'F')
  end

  let(:content)  { 'Message from User One' }

  sessions = %i[one two]

  it 'signs in users' do
    in_browser(:one) do
      visit '/users/sign_in'
      fill_in 'Email', with: @user.email
      fill_in 'Password', with: 'changeme'
      click_button 'Sign in'
      expect(page).to have_content 'Signed in successfully'
    end

    in_browser(:two) do
      visit '/users/sign_in'
      fill_in 'Email', with: @user_two.email
      fill_in 'Password', with: @user_two.password
      click_button 'Sign in'
      expect(page).to have_content 'Signed in successfully'
    end

    sessions.each do |session|
      in_browser(session) do
        find('.left_nav_box').click_link('messages')
        expect(page).to have_content 'MESSAGE BOARD'
      end
    end

    in_browser(:one) do
      save_and_open_screenshot
      fill_in 'msg_content', with: content
      click_link('msg_content')
      save_and_open_screenshot
    end

    in_browser(:two) do
      expect(page).to have_content(content)
      save_and_open_screenshot
    end
  end
end
