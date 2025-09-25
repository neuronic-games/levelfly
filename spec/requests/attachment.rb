# NOTE: This is intended as a smoke-test of file upload functionality completely breaking.
# Perhaps in the fullness of time, each type of upload will be tested with the rest of each controller's methods

require 'rails_helper'

RSpec.describe 'Attachments', type: :request do
  before(:all) do
    @user = User.first
    @school_demo = School.find_by!(handle: 'demo')
    @profile = @user.profiles.first

    @course = FactoryBot.create(:course, school: @school_demo, owner: @profile)
    @participant = FactoryBot.create(:participant, target: @course, target_type: 'Course', profile: @profile,
                                                   profile_type: 'M')
  end

  after(:all) do
    @participant.delete
    @course.delete
  end

  context 'POST /add_file' do
    it 'should redirect to login if unauthenticated' do
      post url_for controller: 'course', action: :add_file
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should attach file' do
      sign_in @user

      post url_for(controller: 'course', action: :add_file),
           params: { file: Rack::Test::UploadedFile.new('app/assets/images/rails.png', 'image/png'), school_id: @school_demo.id, id: @course.id, target_type: 'Course', profile_id: @profile.id }

      expect(response.status).to eq(200)
      expect(response.body).to include 'rails.png'
    end
  end
end
