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

  after_initialize :init_defaults

  has_attached_file :image,
    :storage => :s3,
    :s3_credentials => { :access_key_id => School.vault.account, :secret_access_key => School.vault.secret },
    :path => "schools/:school/courses/:course/tasks/:id/:filename",
    :bucket => School.vault.folder

  @@levels = ["Low", "Medium", "High"]
  cattr_accessor :levels

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
  
  def self.send_task_complete(task_id,check_val)
    status = false
    @participant = TaskParticipant.find(:first,:conditions=>["task_id =?",task_id])
    @task = Task.find_by_id(@participant.task_id)
     if @participant
       @avatar = Avatar.find(:first,:conditions=>["profile_id =?",@participant.task_id])
       if check_val == "true"
          @participant.complete_date = Date.today
          @participant.status = 'C'
          @participant.save
          @avatar.points = @task.points
          @avatar.save
        else
          @participant.complete_date = ""
          @participant.status = 'P'
          @participant.save
          @avatar.points = 0
          @avatar.save
        end
        status = true
      end
      return status
  end
  
end
