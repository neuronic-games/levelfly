require 'rails_helper'
require_relative 'helpers/two_browsers'

# NOTE: Currently un-used as of September 2025, left here as an example if and when we implement browser tests in future

xdescribe 'send board message to friends', js: true do
  before :each do
    # create users with profiles
    p1 = FactoryBot.create(:profile_one)
    p2 = FactoryBot.create(:profile_two)
    # make users friends
    Participant.create(target_id: p2.id, target_type: 'User', profile_id: p1.id, profile_type: 'F')
    Participant.create(target_id: p1.id, target_type: 'User', profile_id: p2.id, profile_type: 'F')
  end

  let(:user_one) { FactoryBot.build(:user_one) }
  let(:user_two) { FactoryBot.build(:user_two) }
  let(:content)  { 'Message from User One' }

  sessions = %i[one two]

  it 'signs in users' do
    in_browser(:one) do
      visit '/users/sign_in'
      fill_in 'Email', with: user_one.email
      fill_in 'Password', with: user_one.password
      click_button 'Sign in'
      expect(page).to have_content 'Signed in successfully'
    end

    in_browser(:two) do
      visit '/users/sign_in'
      fill_in 'Email', with: user_two.email
      fill_in 'Password', with: user_two.password
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
