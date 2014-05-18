class Report < ActiveRecord::Base

  def self.all_members(from_date, school_code)
    puts "REPORT, Members In Detail, #{from_date}, #{school_code}"
    puts
    
    school = School.find(:first, :conditions => ["code = ?", school_code])
    courses = Course.find(:all, :conditions => ["created_at > ? and school_id = ? and archived = ?", from_date, school.id, false], :order => "parent_type, name, code, year, semester")
    people_in_courses = Set.new
    people_in_groups = Set.new
    courses.each do |course|
      participants = Participant.find(:all, :include => [:profile, :profile => [:user]],
        :conditions => ["target_type = ? and target_id = ? and users.status = ?", 'Course', course.id, User.status_active], :order => "profile_type, profiles.full_name")
      puts "#{course.parent_type == Course.parent_type_course ? 'COURSE' : 'GROUP'}, #{course.name}, #{course.id}, #{course.code}, #{course.semester}, #{course.year}, #{participants.count}"
      puts
      participants.each do |participant|
        profile = participant.profile
        case course.parent_type
        when Course.parent_type_course
          people_in_courses.add(profile.id)
        when Course.parent_type_group
          people_in_groups.add(profile.id)
        end
        puts "  #{participant.profile_type == Participant.profile_type_master ? 'ORGANIZER' : 'MEMBER'}, #{profile.full_name}, #{profile.user.id}, #{Setting.default_date_format(profile.user.created_at)}, #{Setting.default_date_time_format(profile.user.last_sign_in_at)}"
      end
      puts
    end
    
    puts "SUMMARY, People in courses, #{people_in_courses.length}"
    puts "SUMMARY, People in groups, #{people_in_groups.length}"
  end

  def self.course_members(from_date, school_code)
    puts "REPORT, Course Members, #{from_date}, #{school_code}"
    puts

    school = School.find(:first, :conditions => ["code = ?", school_code])
    courses = Course.find(:all, :conditions => ["parent_type = ? and created_at > ? and school_id = ? and archived = ?", Course.parent_type_course, from_date, school.id, false], :order => "name")
    people_in_courses = Set.new
    courses.each do |course|
      participants = Participant.find(:all, :include => [:profile, :profile => [:user]],
        :conditions => ["target_type = ? and target_id = ? and users.status = ?", 'Course', course.id, User.status_active])
      participants.each do |participant|
        people_in_courses.add(participant.profile_id)
      end

      puts "COURSE, #{course.name}, #{course.id}, #{course.code}, #{course.semester}, #{course.year}, #{participants.count}"

    end

    all_people = Profile.count(:all, :include => [:user],
      :conditions => ["users.last_sign_in_at > ? and school_id = ? and users.status = ?", from_date, school.id, User.status_active])
      
    puts
    puts "SUMMARY, All people, #{all_people}"
    puts "SUMMARY, People in courses, #{people_in_courses.length}"
    puts "SUMMARY, People not in courses, #{all_people - people_in_courses.length}"
  end

end