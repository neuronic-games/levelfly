class Report < ActiveRecord::Base

  def self.list_members(from_date, school_code)
    puts "REPORT, #{from_date}, #{school_code}"
    puts
    
    school = School.find(:first, :conditions => ["code = ?", school_code])
    courses = Course.find(:all, :conditions => ["created_at > ? and school_id = ?", from_date, school.id], :order => "name")
    people_in_courses = Set.new
    courses.each do |course|
      participants = Participant.find(:all, :include => [:profile], 
        :conditions => ["target_type = ? and target_id = ?", 'Course', course.id], :order => "profiles.full_name")
      puts "COURSE, #{course.name}, #{course.id}, #{course.code}, #{course.semester}, #{course.year}, #{participants.count}"
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
    
    puts "SUMMARY, People in courses, #{people_in_courses.length}"
  end

  def self.summary(from_date, school_code)
    puts "REPORT, #{from_date}, #{school_code}"
    puts

    school = School.find(:first, :conditions => ["code = ?", school_code])
    courses = Course.find(:all, :conditions => ["created_at > ? and school_id = ?", from_date, school.id], :order => "name")
    people_in_courses = Set.new
    courses.each do |course|
      participants = Participant.find(:all, 
        :conditions => ["target_type = ? and target_id = ?", 'Course', course.id])
      puts "COURSE, #{course.name}, #{course.id}, #{course.code}, #{course.semester}, #{course.year}, #{participants.count}"

      participants.each do |participant|
        people_in_courses.add(participant.profile_id)
      end
    end

    all_people = Profile.count(:all, :include => [:user],
      :conditions => ["users.last_sign_in_at > ? and school_id = ?", from_date, school.id])
      
    puts
    puts "SUMMARY, All people, #{all_people}"
    puts "SUMMARY, People in courses, #{people_in_courses.length}"
    puts "SUMMARY, People not in courses, #{all_people - people_in_courses.length}"
  end

end