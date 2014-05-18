class Admin < ActiveRecord::Base
  
  def self.clean_friends
    pmap = {}
    count = 0
    plist = Participant.find(:all, :conditions => {:target_type => "User", :profile_type => "F"})
    plist.each do |p|
      index = "#{p.target_id},#{p.profile_id}"
      if pmap[index].nil?
        pmap[index] = p.id
      else
        Participant.delete(p.id)
        count += 1
        puts "Deleting Participant id:#{p.id} #{index}"
      end
    end
    puts "#{count} deleted"
    return count
  end
  
  # Reset all icons to the default
  def self.reset_icons
    Profile.update_all("image_file_name = '/images/wardrobe/null_profile.png'")
    Course.update_all("image_file_name = null, image_content_type = null, image_file_size = null")
    Task.update_all("image_file_name = null, image_content_type = null, image_file_size = null")
  end
  
  # Make sure all users have the correct level and wardrobe rewards
  def self.reset_rewards
    profiles = Profile.all
    profiles.each do |profile|
      profile.update_rewards
    end
  end

  def self.make_email_safe
    profiles = Profile.all
    profiles.each do |profile|
      profile.make_email_safe
    end
  end
  
  def self.list_members(from_date, school_code)
    puts "REPORT, #{from_date}, #{school_code}"
    puts
    
    school = School.find(:first, :conditions => ["code = ?", school_code])
    courses = Course.find(:all, :conditions => ["created_at > ? and school_id = ?", from_date, school.id])
    people_in_courses = Set.new
    courses.each do |course|
      participants = Participant.find(:all, :conditions => ["target_type = ? and target_id = ?", 'Course', course.id])
      puts "COURSE, #{course.name}, #{course.id}, #{participants.count}"
      puts
      i = 0
      participants.each do |participant|
        i += 1
        profile = participant.profile
        people_in_courses.add(profile.id)
        puts "  MEMBER, #{i}, #{profile.full_name}, #{profile.user.id}, #{Setting.default_date_format(profile.user.created_at)}, #{Setting.default_date_time_format(profile.user.last_sign_in_at)}"
      end
      puts
    end
    
    puts "People in courses: #{people_in_courses.length}"
  end
  
end