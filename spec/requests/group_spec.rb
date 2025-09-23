# frozen_string_literal: true

# NOTE: Groups are a special case of Courses, so in theory these tests could also live in ./course_spec.rb – but it was already getting rather long!

require 'rails_helper'

RSpec.describe 'Groups', type: :request do
  before(:all) do
    @user = User.first
    @school_demo = School.find_by!(handle: 'demo')
    @profile = @user.profiles.first

    # NOTE: See note in ./course_spec.rb
    @group = FactoryGirl.create(:course, :group, school: @school_demo, owner: @profile)
    @participant = FactoryGirl.create(:participant, target: @group, target_type: 'Course', profile: @profile,
                                                    profile_type: 'M')
  end

  after(:all) do
    @participant.delete
    @group.delete
  end

  context 'POST /filter' do
    it 'should redirect to login if unauthenticated' do
      post url_for(controller: 'course', action: :filter),
           params: { filter: 'M', section_type: Course.parent_type_group }
      expect(response).to redirect_to '/users/sign_in'
    end

    it 'should render filter results' do
      sign_in @user
      post url_for(controller: 'course', action: :filter),
           params: { filter: 'M', section_type: Course.parent_type_group }
      File.write('crash.html', response.body)
      expect(response.body).to include @group.name
    end
  end
end
