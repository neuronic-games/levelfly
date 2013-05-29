class Course < ActiveRecord::Base
  belongs_to :school
  has_many :participants, :as => :object
  has_many :messages, :as => :parent
  has_many :categories
  #has_many :outcomes
  has_and_belongs_to_many :outcomes
  has_many :attachments, :as => :object
  has_attached_file :image,
    :storage => :s3,
    :s3_credentials => { :access_key_id => School.vault.account, :secret_access_key => School.vault.secret },
    :path => "schools/:school/courses/:id/:filename",
    :bucket => School.vault.folder
  
  after_initialize :init_defaults
  
  # Defaults
  
  @@default_points_max = 1000  # Total XP that a course may give out
  cattr_accessor :default_points_max
  
  # These 3 numbers defines the ratio of XP given out by low, medium and high rating tasks
  
  @@default_rating_low = 1
  cattr_accessor :default_rating_low

  @@default_rating_medium = 3
  cattr_accessor :default_rating_medium

  @@default_rating_high = 10
  cattr_accessor :default_rating_high

  # These 3 numbers are the recommended number of tasks for a course
  
  @@default_tasks_low = 10
  cattr_accessor :default_tasks_low

  @@default_tasks_medium = 5
  cattr_accessor :default_tasks_medium

  @@default_tasks_high = 2
  cattr_accessor :default_tasks_high

  # This is the default course icon

  @@default_image_file = "/images/course_img_default.jpg"
  cattr_accessor :default_image_file

  @@parent_type_group = 'G'
  cattr_accessor :parent_type_group

  @@parent_type_course = 'C'
  cattr_accessor :parent_type_course

  @@parent_type_group = 'G'
  cattr_accessor :parent_type_group

  @@join_type_invite = 'I'
  cattr_accessor :join_type_invite

  @@profile_type_master = 'M'
  cattr_accessor :profile_type_master

  @@profile_type_student = 'S'
  cattr_accessor :profile_type_student

  @@profile_type_pending = 'P'
  cattr_accessor :profile_type_pending
  
  @owner = nil
  
  def image_file
    return image_file_name ? image.url : Course.default_image_file
  end
  
  def init_defaults
    self.rating_low = Course.default_rating_low
    self.rating_medium = Course.default_rating_medium
    self.rating_high = Course.default_rating_high

    self.tasks_low = self.tasks_low.blank? ? Course.default_tasks_low : self.tasks_low
    self.tasks_medium = self.tasks_medium.blank? ? Course.default_tasks_medium : self.tasks_medium
    self.tasks_high = self.tasks_high.blank? ? Course.default_tasks_high : self.tasks_high
  end
  
  def code_section
    return "#{self.code}#{'-' unless self.section.blank?}#{self.section}"
  end
  
  # The number of points that remains unallocated. Sum up the the points for all tasks associated
  # with this course, plus any extra credit, and minus from the max 1000 points.
  def remaining_points
    total_points = Task.sum(:points,
      :conditions => ["course_id = ? and archived = ?", self.id, false])
    
    # FIXME: What about rainy-day bucket and extra credit tasks?
    
    return Course.default_points_max - total_points
  end
  
  def owner
    if @owner == nil
      @owner = Profile.find(
      :first, 
      :include => [:participants], 
      :conditions => ["participants.object_id = ? AND participants.object_type='Course' AND participants.profile_type = 'M'", self.id]
      )
    end
    return @owner
  end
  
  def self.get_top_achievers(school_id,course_id,outcome_id)
    member_ids = Profile.find(
       :all, 
       :include => [:participants], 
       :conditions => ["participants.object_id = ? AND participants.profile_type IN ('P', 'S')", course_id]
     ).map(&:id)
    @students = CourseGrade.where("school_id = ? and course_id = ? and outcome_id = ? and grade >= '2' and profile_id in (?)",school_id,course_id,outcome_id,member_ids).order("grade DESC")
    sorted_gpa = Course.sort_top_achievers(@students,school_id,course_id,"GPA")
    sorted_total_xp = Course.sort_top_achievers(sorted_gpa,school_id,course_id,"XP")
    return sorted_total_xp.uniq[0..4]
  end
  
  def self.sort_top_achievers(students,school_id,course_id,sort_type)
    sorted_array = []
    outcome_grades = students.map(&:grade)
    profile_ids = students.map(&:profile_id)
    temp = 0
    outcome_grades.each_with_index do |og,i|
      if i >= temp
        count = outcome_grades.count(outcome_grades[i])
        temp = temp+count
        if count > 1
          if sort_type == "GPA"
            course_grades = CourseGrade.where("school_id = ? and course_id = ? and profile_id in (?) and outcome_id is null and grade is not null",school_id,course_id,profile_ids[i..count+i-1]).order("grade DESC")
            sorted_array.concat(course_grades)
            p_ids = profile_ids[i..count+i-1]
            c_ids = course_grades.map(&:profile_id)
            remaining_people = p_ids-c_ids
            if remaining_people.count > 0
              remaining_people.each do |people|
                sorted_array.push(students[profile_ids.find_index(people)])
              end
            end
          else
            profiles = Profile.find(:all, :conditions => ["id in (?)", profile_ids[i..count+i-1]], :order => "xp desc")
            sorted_array.concat(profiles)
          end
        else
          sorted_array.push(students[i]) if sort_type == "GPA"
          sorted_array.push(students[i].profile) if sort_type == "XP"
        end
      end
    end
    return sorted_array
  end
  
  def self.all_group(profile,filter)
    if filter == "M"
    @courses = Course.find(
            :all, 
            :select => "distinct *",
            :include => [:participants], 
            :conditions => ["removed = ? and participants.profile_id = ? AND parent_type = ? AND participants.profile_type != ? AND courses.archived = ?", false, profile.id, Course.parent_type_group, Course.profile_type_pending, false],
            :order => 'courses.name'
          )
    else
     @courses = Course.find(:all, :conditions=>["removed = ? AND parent_type = ? AND school_id = ?",false, Course.parent_type_group,profile.school_id], :order => 'courses.name')
    end    
    return @courses      
  end
  
  def self.course_filter(profile_id,filter)
    if filter == "active" or filter == ""
      archived = false
    else
      archived = true
    end
     @courses = Course.find(
            :all, 
            :select => "distinct *",
            :include => [:participants], 
            :conditions => ["removed = ? and participants.profile_id = ? AND parent_type = ? AND join_type = ? AND participants.profile_type != ? AND courses.archived = ?",false, profile_id, Course.parent_type_course, Course.join_type_invite, Course.profile_type_pending, archived],
            :order => 'courses.name'
            )
    return @courses      
  end
  
  def self.hexdigest_to_string(string)
    string.unpack('U'*string.length).collect {|x| x.to_s 16}.join
  end
  
   def self.hexdigest_to_digest(hex)
    hex.unpack('a2'*(hex.size/2)).collect {|i| i.hex.chr }.join
  end
  
  def self.sort_course_task(course_id)
    @tasks = [];
    task_ids = Task.find(
      :all, 
      :include => [:category], 
      :conditions => ["tasks.course_id = ? and tasks.archived = ? and (tasks.category_id is null or tasks.category_id = ?)",course_id,false,0],
      :order => "tasks.due_date,tasks.created_at"
    ).map(&:id)
    categorised_task_ids = Task.find(
      :all,
      :include => [:category], 
      :conditions => ["tasks.course_id = ? and categories.course_id = ? and tasks.archived = ?",course_id,course_id,false], 
      :order => "percent_value,categories.name,due_date,tasks.created_at"
    ).map(&:id)
    task_ids.concat(categorised_task_ids)
    task_ids.each do |task_id|
      @tasks.push(Task.find(task_id))
    end
   return @tasks
  end
  
  
  def course_forum(profile_id = nil)
    return Course.find(:all,:include => [:participants],:conditions => ["participants.profile_id = ? AND course_id = ? AND archived = ? AND removed = ?",profile_id,self.id,false, false], :order => 'courses.name')
  end
  
  def join_all(profile)
     @all_members = Profile.find(
           :all, 
           :include => [:participants], 
           :conditions => ["participants.object_id = ? AND participants.object_type in ('Course','Group') AND participants.profile_type IN ('M', 'S')", self.course_id]
         )
     if @all_members and not@all_members.nil?
        @all_members.each do |viewer|
           participant_exist = Participant.find(:first, :conditions => ["object_id = ? AND object_type = 'Course' AND profile_id = ?",self.id , viewer.id])
          if !participant_exist
            @participant = Participant.new
            @participant.object_id = self.id
            @participant.object_type = "Course"
            @participant.profile_id = viewer.id
            @participant.profile_type = "S"
            if @participant.save
              wall_id = Wall.get_wall_id(self.id,"Course")
              Feed.create(
                :profile_id => viewer.id,
                :wall_id =>wall_id
              )
              course = Course.find(self.course_id)
              content = "#{profile.full_name} added you to a new forum in #{course.name} #{course.section}: #{self.name}"   
              Message.send_notification(profile.id,content,viewer.id) 
            end
          end
      end     
    end
  end
  
  
end
