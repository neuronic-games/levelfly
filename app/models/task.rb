class Task < ActiveRecord::Base
  has_many :group
  belongs_to :category
  belongs_to :school
  belongs_to :task
  belongs_to :course
  belongs_to :group
  has_many :task_participants
  has_many :participants, :as => :object
  has_many :attachments, :as => :object
  has_many :messages, :as => :parent
  has_many :outcome_tasks
  has_many :outcomes, :through => :outcome_tasks
  
  after_initialize :init_defaults

  has_attached_file :image,
    :storage => :s3,
    :s3_credentials => { :access_key_id => School.vault.account, :secret_access_key => School.vault.secret },
    :path => "schools/:school/courses/:course/tasks/:id/:filename",
    :bucket => School.vault.folder

  @@levels = ["Low", "Medium", "High"]
  cattr_accessor :levels

  @@profile_type_owner = 'O'
  cattr_accessor :profile_type_owner

  @@profile_type_member = 'M'
  cattr_accessor :profile_type_member

  @@status_assigned = 'A'
  cattr_accessor :status_assigned

  @@status_complete = 'C'
  cattr_accessor :status_complete

  @@status_incomplete = 'I'
  cattr_accessor :status_incomplete

  @@status_pending = 'P'
  cattr_accessor :status_pending

  def init_defaults
    #self.level = 0
  end
    
  def image_file
    return image_file_name ? image.url : Course.default_image_file
  end 

  def outcomes
    return OutcomeTask.find(:all, :conditions => ["task_id = ?", self.id]).collect {|x| x.outcome}
  end
  
  def show_date_format(the_date)
    return the_date.strftime('%d/%m/%Y')
  end
  
  
  def self.filter_by(profile_id, filter, period)
    conditions = ["task_participants.profile_id = ? and archived = ?", profile_id, false]

    if filter == "starred"
      conditions[0] += " and task_participants.priority = ?"
      conditions << 'H'
    elsif !filter.to_s.empty?
      conditions[0] += " and course_id = ?"
      conditions << filter.to_i
    end
    
    if period == "current"
      conditions[0] += " and task_participants.complete_date is null"
    elsif period == "past"
      conditions[0] += " and task_participants.complete_date is not null"
    end

    tasks = Task.find(
      :all, 
      :include => [:task_participants], 
      :conditions => conditions,
      :order => "due_date"
    )
  end
  
  # Calculate the point value of this task based on the task rating and the task estimate counts
  # in the associated course. Each course is allocated a total of 1000 points that are distributed
  # to all the tasks associated with the course. The amount of points is also weighted by the task
  # raiting.
  def calc_point_value
    return 0 if self.course.nil?
    return 0 if self.level.nil? or self.level > 2 or self.level < 0

    remaining_points = self.course.remaining_points
    return 0 unless remaining_points > 0
    
    # level = 0,1,2
    rating_ratio = [self.course.rating_low, self.course.rating_medium, self.course.rating_high]

    # Calculate how many units in total are estimated for the course
    total_units = self.course.rating_low * self.course.tasks_low +
      self.course.rating_medium * self.course.tasks_medium +
      self.course.rating_high * self.course.tasks_high

    # Calculate how much one unit is worth in terms of XP
    unit =  self.course.default_points_max / total_units
    
    # Calculate how much XP this task should be allocated. We will need to track how much points
    # have been allocated to the course over the life of the course. If the allocated points is over
    # the max (1000 points), then no more points can be allocated to tasks for this course.
    suggested_points = unit * rating_ratio[self.level]
    suggested_points = remaining_points if remaining_points < suggested_points
    self.points = suggested_points
  end
  
  def rating_icon_file
    return "/images/ui/task_rating_#{self.level}.png"
  end
  
  # Mark the task as complete and give points
  def self.complete_task(task_id, complete, profile_id)
    status = nil
    participant = TaskParticipant.find(:first,
      :include => [:profile, :task],
      :conditions => ["task_id = ? and profile_id = ?", task_id, profile_id])
    return status if participant.nil?
    
    profile = participant.profile
    task = participant.task

    if participant.profile_type == Task.profile_type_owner
      # If the owner marks the task as complete, we need to close out the task for all members,
      # and mark it incomplete for them. Owner does not get points. There is no going back on this action.
      participant.complete_date = Time.now
      participant.status = Task.status_complete
      participant.save
      #participants = TaskParticipant.find(:all,
       # :include => [:profile, :task],
        #:conditions => ["task_id = ? and profile_type = ? and status <> ?", task_id, Task.profile_type_member, Task.status_complete])
      # participants.each do |a_participant|
        # a_participant.complete_date = Time.now
        # a_participant.status = Task.status_incomplete
        # a_participant.save
      # end
      #Task.task_grade_points(task_id,profile_id,complete)
      status = true
    elsif participant.profile_type == Task.profile_type_member
      participant.complete_date = complete ? Time.now : nil
      # if  participant.status ==  Task.status_complete
        # profile.xp += complete ? task.points : -task.points
      # end
      participant.status = complete ? Task.status_complete : Task.status_assigned
      participant.save
      #profile.save
      status = complete
    end   
    return status
  end  
  
  def self.task_grade_points(task_id,profile_id,complete)
    @task = Task.find(task_id)
    @task_grade = TaskGrade.where("task_id = ? and profile_id = ?", task_id ,profile_id)
    if !@task_grade.nil?
      @task_grade.each do |t|
        t.points = complete ? @task.points : nil
        t.save
      end
    end
  end
  
  def self.points_to_student(task_id, complete, profile_id)
    status = nil
    previous_level=nil
    participant = TaskParticipant.find(:first,
      :include => [:profile, :task],
      :conditions => ["task_id = ? and profile_id = ?", task_id, profile_id])
    if participant
      profile = participant.profile
      task = participant.task
      previous_level = profile.level
      if participant.profile_type == Task.profile_type_member
      # Give points to members who completed the task
        participant.xp_award_date = complete ? Time.now : nil
        profile.xp += complete ? task.points : -task.points
        participant.save
        status = complete
        Task.task_grade_points(task_id,profile_id,complete)
        @level = Reward.find(:first, :conditions=>["xp <= ?",  profile.xp], :order=>"xp DESC")  
        puts"#{@level.inspect}"
        profile.level = @level.object_id
        profile.save
        if(previous_level != profile.level)
          Message.change_level(profile_id,profile.level,profile_id)
        end  
      end
    end
    return status
  end
end
