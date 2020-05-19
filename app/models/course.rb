class Course < ActiveRecord::Base
  include Comparable
  
  belongs_to :school
  has_many :participants, :as => :target
  has_many :messages, :as => :parent
  has_many :categories
  has_many :tasks, :order => :due_date
  #has_many :outcomes
  has_and_belongs_to_many :outcomes
  has_many :attachments, :as => :target
  has_attached_file :image,
   :storage => :s3,
   :s3_credentials => { :access_key_id => ENV['S3_KEY'], :secret_access_key => ENV['S3_SECRET'] },
   :path => "schools/:school/courses/:id/:filename",
   :bucket => ENV['S3_PATH'],
   :s3_protocol => ENV['S3_PROTOCOL']

  has_many :forums, :class_name => 'Course', :conditions => {:parent_type => "F"}, :order => :name
  has_one :wall, :as => :parent
  has_one :game

  after_initialize :init_defaults
  after_save :save_messages
  after_save :save_owner

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

  @@parent_type_forum = 'F'
  cattr_accessor :parent_type_forum

  @@join_type_invite = 'I'
  cattr_accessor :join_type_invite

  @@profile_type_master = 'M'
  cattr_accessor :profile_type_master

  @@profile_type_student = 'S'
  cattr_accessor :profile_type_student

  @@profile_type_pending = 'P'
  cattr_accessor :profile_type_pending

  @owner = nil
  @messages = nil

  # Orders by the semester, most recent course appearing first
  def <=>(other)
    # Not camparable if year is not defined. Don't want to return nil to prevent breakage, but this should not exist.
    return 1 if year.nil? || other.year.nil?
    
    # Ordered last if no period defined
    return 1 if semester.blank? && year.blank?
    
    # Different year
    return 1 if year < other.year
    return -1 if year > other.year

    # Same year & semester
    return name <=> other.name if semester == other.semester

    # Same year
    sort_order = ["Fall", "Summer II", "Summer I", "Spring", "Winter"]
    return sort_order.index(semester) <=> sort_order.index(other.semester)
  end
  
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

  def semester_year
    return "#{self.year}" if self.semester.blank?
    return "#{self.semester}" if self.year.blank?
    return "#{self.semester} #{self.year}"
  end
  
  # The number of points that remains unallocated. Sum up the the points for all tasks associated
  # with this course, plus any extra credit, and minus from the max 1000 points.
  def remaining_points
    total_points = Task.sum(:points,
      :conditions => ["course_id = ? and archived = ?", self.id, false])

    # FIXME: What about rainy-day bucket and extra credit tasks?

    return Course.default_points_max - total_points
  end

  def self.is_owner?(course_id, profile_id)
    owner = Profile.find(
      :first,
      :include => [:participants],
      :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", course_id],
      :joins => [:participants]
    )
    return false if owner.nil?
    return owner.id == profile_id
  end
  
  def owner
    if @owner == nil
      @owner = Profile.find(
      :first,
      :include => [:participants],
      :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", self.id],
      :joins => [:participants],
      )
    end
    return @owner
  end

  def owner=(o)
    attributes = {:target_type => 'Course', :profile_type => 'M', :target_id => self.id}
    if p = Participant.find(:first, :conditions => attributes)
      p.profile = o
      # p.save
    else
      p = Participant.new
      p.target = self
      p.profile_type = 'M'
      p.profile = o
      # p.save
    end
    @owner = p
  end

  def save_owner
    @owner.save if @owner
  end

  def messages
    @messages ||= Message.where({ :target_id => self.id, :target_type => self.parent_type }).order('starred DESC, created_at DESC')
  end

  def messages=(m)
    @messages = m
  end

  def save_messages
    # this only really needs to fire when a course is duplicated
    if @messages
      self.messages.each do |m|
        m.target_type = self.parent_type || 'C'
        m.target_id = self.id
        m.parent_type = m.target_type
        m.parent_id = m.target_id

        mv = MessageViewer.new
        mv.poster_profile = self.owner.profile
        mv.viewer_profile = self.owner.profile
        m.message_viewers.push mv

        m.save
      end
    end
  end

  def self.get_top_achievers(school_id,course_id,outcome_id)
    member_ids = Profile.find(
       :all,
       :include => [:participants],
       :conditions => ["participants.target_id = ? AND participants.profile_type IN ('P', 'S')", course_id],
      :joins => [:participants],
     ).map(&:id)
    @students = CourseGrade.where("school_id = ? and course_id = ? and outcome_id = ? and grade >= '2.1' and profile_id in (?)",school_id,course_id,outcome_id,member_ids).order("grade DESC")
    sorted_gpa = Course.sort_top_achievers(@students,school_id,course_id,"GPA")
    sorted_total_xp = Course.sort_top_achievers(sorted_gpa,school_id,course_id,"XP")
    return sorted_total_xp.uniq[0..4]
  end
  
  # Returns the total XP assigned for the course (in Tasks)
  def get_xp
    return Task.where(:course_id => self.id, :archived => false).sum(:points)
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
            :conditions => [
              "removed = ? and participants.profile_id = ? AND parent_type = ? AND participants.profile_type != ? AND courses.archived = ?", 
              false, profile.id, Course.parent_type_group, Course.profile_type_pending, false
            ],
            :order => 'courses.name',
            :joins => [:participants]
          )
    else
      @courses = Course.find(
        :all,
        :conditions => [
          "removed = ? AND parent_type = ? AND school_id = ?",
          false,
          Course.parent_type_group,
          profile.school_id
        ],
        :order => 'courses.name'
      )
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
            :order => 'courses.name',
            :joins => [:participants]
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
      :conditions => [
        "tasks.course_id = ? and categories.course_id = ? and tasks.archived = ?",
        course_id,course_id,false
      ],
      :order => "percent_value,categories.name,due_date,tasks.created_at",
      :joins => [:category],
    ).map(&:id)
    task_ids.concat(categorised_task_ids)
    task_ids.each do |task_id|
      @tasks.push(Task.find(task_id))
    end
   return @tasks
  end
  
  def self.search(text)
    d = text.downcase
    Course.find(:all,
      :conditions => ["(lower(courses.name) LIKE ? OR lower(courses.code) LIKE ?) and parent_type = ? and school_id = ? and removed = ?", d, d, Course.parent_type_course, @profile.school_id, false]
    )
  end

  def course_forum(profile_id = nil)
    return Course.find(
      :all,
      :include => [:participants],
      :conditions => [
        "participants.profile_id = ? AND course_id = ? AND archived = ? AND removed = ?",
        profile_id, self.id, false, false
      ], 
      :order => 'courses.name',
      :joins => [:participants]
    )
  end

  def join_all(profile)
     @all_members = Profile.find(
       :all,
       :include => [:participants],
       :conditions => [
         "participants.target_id = ? AND participants.target_type in ('Course','Group') AND participants.profile_type IN ('M', 'S')", 
         self.course_id
       ],
       :joins => [:participants]
     )
     if @all_members and not@all_members.nil?
        @all_members.each do |viewer|
           participant_exist = Participant.find(:first, :conditions => ["target_id = ? AND target_type = 'Course' AND profile_id = ?",self.id , viewer.id])
          if !participant_exist
            @participant = Participant.new
            @participant.target_id = self.id
            @participant.target_type = "Course"
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

  def duplicate(params = {}, current_user = nil)
    categories = {}
    outcomes = {}

    duplicate = self.dup
    duplicate.owner = self.owner
    duplicate.wall = self.wall.dup if self.wall

    if params[:name_ext]
      name = "#{duplicate.name} #{params[:name_ext]}"
      duplicate.name = name
      i = 0

      while existing = Course.find(:first, :conditions => {:name => duplicate.name, :archived => false, :removed => false}) do
        i = i + 1
        duplicate.name = "#{name}#{i}"
      end
    end

    self.outcomes.each do |outcome|
      outcomes[outcome.id] ||= outcome.dup
      duplicate.outcomes << outcomes[outcome.id]
    end

    begin
      duplicate.image = self.image
    rescue
      logger.error "AWS::S3::NoSuchKey: #{self.image.url}"
    end

    self.categories.each do |category|
      categories[category.id] ||= category.dup
      duplicate.categories << categories[category.id]
    end

    self.course_forum(self.owner.id).each do |forum|
      duplicate.forums.push forum.duplicate
    end

    self.messages.where(:starred => true, :archived => false, :profile_id => self.owner.id).each do |message|
      m = message.dup
      m.wall = duplicate.wall
      m.like = 0
      duplicate.messages.push m
    end

    self.attachments.each do |attachment|
      if attachment.owner == duplicate.owner.profile
        a = Attachment.new

        a.target = duplicate
        a.school = attachment.school
        a.owner = attachment.owner
        a.starred = attachment.starred

        begin
          a.resource = attachment.resource
        rescue
          # a.resource = nil
          logger.error "AWS::S3::NoSuchKey: #{attachment.resource.url}"
        end

        duplicate.attachments << a
      end
    end

    self.tasks.each do |task|
      t = task.dup
      t.due_date = nil
      t.course = duplicate

      if task.category
        categories[task.category.id] ||= task.category.dup
        t.category = categories[task.category.id]
      end

      t.image = task.image unless task.image_file == Course.default_image_file

      task.outcome_tasks.each do |outcome_task|
        outcomes[outcome_task.outcome.id] ||= outcome_task.outcome.dup
        ot = outcome_task.dup
        ot.task = t
        ot.outcome = outcomes[outcome_task.outcome.id]
        t.outcome_tasks << ot
      end

      task.attachments.each do |attachment|
        if attachment.owner == duplicate.owner.profile
          a = Attachment.new

          a.target = t
          a.school = attachment.school
          a.owner = attachment.owner
          a.starred = attachment.starred

          begin
            a.resource = attachment.resource
          rescue
            # a.resource = nil
            logger.error "AWS::S3::NoSuchKey: #{attachment.resource.url}"
          end

          t.attachments << a
        end
      end

      task.task_participants.each do |task_participant|
        if task_participant.profile_type == 'O'
          tp = task_participant.dup
          tp.task = t
          tp.status = Task.status_assigned
          tp.complete_date = nil
          t.task_participants << tp
        end
      end

      duplicate.tasks << t
    end

    if current_user
      duplicate.save
      Pusher["course-duplicate-#{current_user.id}"].trigger('complete', {})
    else
      duplicate
    end
  end

  def finalize(current_profile)
    status = false
    grading_completed_at = Time.now
    save
    @outcomes = outcomes.order('name')
    @participant = Participant.all( 
      :joins => [:profile], 
      :conditions => [
        "participants.target_id=? AND participants.profile_type = 'S' AND target_type = 'Course'", id
      ],
      :select => [
        "profiles.full_name,participants.id,participants.profile_id"
      ]
    )
    @participant.each do |p|
      TaskGrade.bonus_points(p.profile.school_id, self, p.profile.id, current_profile.id)
      outcomes_grade = []
      if !@outcomes.nil?
        @outcomes.each do |o|
          outcome_grade = CourseGrade.load_outcomes(p.profile_id, id, o.id, current_profile.school_id)
          if !outcome_grade.blank? and outcome_grade >= 2.5
            @badge = Badge.gold_outcome_badge(o.name, current_profile)
            avatar_badge = AvatarBadge.find(:first, :conditions => ["profile_id = ? and badge_id = ? and course_id = ? and giver_profile_id = ?",p.profile_id,@badge.id,id,current_profile.id]) if @badge
            if avatar_badge.nil?
              status = AvatarBadge.add_badge(p.profile_id, @badge.id, id, current_profile.id)
            end
          end
        end
      end
    end
    Pusher["course-finalize-#{current_profile.user.id}"].trigger('complete', {:status => status})
  end

  def self.all_archived_courses_by_school(school_id)
    find(:all, :select => "distinct *", :conditions => ["archived = ? and removed = ? and parent_type = ? and name is not null and school_id = ?", true, false, Course.parent_type_course, school_id], :order => "name")
  end

  def self.all_courses_by_school(school_id)
    find(:all, :select => "distinct *", :conditions => ["archived = ? and removed = ? and parent_type = ? and name is not null and school_id = ?", false, false, Course.parent_type_course, school_id], :order => "name")
  end

  def self.all_groups_by_school(school_id)
    find(:all, :select => "distinct *", :conditions => ["archived = ? and removed = ? and parent_type = ? and name is not null and school_id = ?", false, false, Course.parent_type_group, school_id], :order => "name")
  end

  class << self
    def get_courses_by_year_range(params)
      fall_on = params[:year_range]
      semester = fall_on.split(' ').first
      seq_semester = fall_on.split(' ').first
      year = fall_on.split(' ').last    
      all_courses = Course.all_courses_by_school(params[:school_id]).map(&:id)
      archived_courses = Course.all_archived_courses_by_school(params[:school_id]).map(&:id).uniq
      all_course_ids = all_courses + archived_courses
      courses = []  
      if semester == 'All'
        courses = Course.where(:id => all_course_ids, :year => year.to_i, :semester =>  Course.pluck(:semester).compact.uniq)
      elsif semester == "Summer"
        courses = Course.where(:id => all_course_ids, :year => year.to_i, :semester => semester+' '+seq_semester)
      else
        courses = Course.where(:id => all_course_ids, :year => year.to_i, :semester => semester)
      end
      return courses.try(:order, "updated_at DESC")
    end
  end

end
