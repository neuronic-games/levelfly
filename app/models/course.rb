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

    self.tasks_low = Course.default_tasks_low
    self.tasks_medium = Course.default_tasks_medium
    self.tasks_high = Course.default_tasks_high
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
    @students = CourseGrade.where("school_id = ? and course_id = ? and outcome_id = ? and grade > '2'",school_id,course_id,outcome_id).order("grade DESC")
    return @students
  end
  
  def self.all_group(profile_id)
    @courses = Course.find(
            :all, 
            :select => "distinct *",
            :include => [:participants], 
            :conditions => ["participants.profile_id = ? AND parent_type = ? AND join_type = ? AND participants.profile_type != ? AND courses.archived = ?", profile_id, Course.parent_type_group, Course.join_type_invite, Course.profile_type_pending, false],
            :order => 'name'
          )
    return @courses      
  end
  
end
