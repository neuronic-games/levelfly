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
  after_create :image_save

 has_attached_file :image,
   :storage => :s3,
   :s3_credentials => { :access_key_id => ENV['S3_KEY'], :secret_access_key => ENV['S3_SECRET'] },
   :path => "schools/:school/courses/:course/tasks/:id/:filename",
   :bucket => ENV['S3_PATH']

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
	
	@owner = nil

  def init_defaults
    #self.level = 0
  end
    
  def image_file
    return image_file_name ? image.url : Course.default_image_file
  end

  def image_save
    self.image.save
  end

  def outcomes
    return OutcomeTask.find(:all, :conditions => ["task_id = ?", self.id]).collect {|x| x.outcome}
  end
  
  def show_date_format(the_date)
    return the_date.strftime('%d/%m/%Y')
  end
  
  
  def self.filter_by(profile_id, filter, period, page = nil)
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

    tasks = Task.paginate(
      :include => [:task_participants], 
      :conditions => conditions,
      :order => "priority asc,due_date",
      :page => page || 1,
      :per_page => page ? 20 : Task.count
    )
  end
  
  def self.sort_tasks(profile_id,course_id)
    @tasks = [];
    task_ids = Task.find(
      :all, 
      :include => [:category, :task_participants], 
      :conditions => ["tasks.course_id = ? and task_participants.profile_id = ? and tasks.archived = ? and (tasks.category_id is null or tasks.category_id = ?)",course_id,profile_id,false,0],
      :order => "tasks.due_date,tasks.created_at"
    ).map(&:id)
    categorised_task_ids = Task.find(
      :all,
      :include => [:category, :task_participants], 
      :conditions => ["tasks.course_id = ? and task_participants.profile_id = ? and categories.course_id = ? and tasks.archived = ?",course_id,profile_id,course_id,false], 
      :order => "percent_value,categories.name,due_date,tasks.created_at"
    ).map(&:id)
    task_ids.concat(categorised_task_ids)
    task_ids.each do |task_id|
      @tasks.push(Task.find(task_id))
    end
   return @tasks
  end
  # Calculate the point value of this task based on the task rating and the task estimate counts
  # in the associated course. Each course is allocated a total of 1000 points that are distributed
  # to all the tasks associated with the course. The amount of points is also weighted by the task
  # raiting.
  def calc_point_value
    return 0 if self.course.nil?
    return 0 if self.level.nil? or self.level > 2 or self.level < 0
    estimated_tasks = self.course.tasks_low if self.level == 0
    estimated_tasks = self.course.tasks_medium if self.level == 1
    estimated_tasks = self.course.tasks_high if self.level == 2
    # level = 0,1,2
    rating_ratio = [self.course.rating_low, self.course.rating_medium, self.course.rating_high]

    # Calculate how many units in total are estimated for the course
    total_units = self.course.rating_low + self.course.rating_medium + self.course.rating_high

    # Calculate how much one unit is worth in terms of XP
    unit =  self.course.default_points_max / total_units.to_f
    
    # Calculate how much XP this task should be allocated. We will need to track how much points
    # have been allocated to the course over the life of the course. If the allocated points is over
    # the max (1000 points), then no more points can be allocated to tasks for this course.
    all_tasks = Task.filter_by(self.course.owner.id,self.course.id,"").collect(&:level)
    new_estimated_tasks = all_tasks.count(self.level)
    if new_estimated_tasks > estimated_tasks
      suggested_points = unit * rating_ratio[self.level] / new_estimated_tasks
    else
      suggested_points = unit * rating_ratio[self.level] / estimated_tasks
    end
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
      participant.complete_date = complete ? Time.now : nil
      participant.status = complete ? Task.status_complete : Task.status_assigned
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
  
  def self.task_grade_points(task_id,profile_id,complete,award_points)
    @task = Task.find(task_id)
    @task_grade = TaskGrade.where("task_id = ? and profile_id = ?", task_id ,profile_id)
    @task_grade << TaskGrade.new({:school_id => @task.school_id, :course_id => @task.course_id, :task_id => task_id, :profile_id => profile_id}) if @task_grade.blank?
    if !@task_grade.nil?
      @task_grade.each do |t|
        t.points = complete ? award_points : nil
        t.save
      end
    end
  end
  
  def self.award_xp(complete,profile,participant,task,award_points,current_user,course_name = nil)
    previous_level = profile.level
    previous_points = profile.xp
    previous_wardrobe = profile.wardrobe
    if complete
      profile.xp += award_points if (participant and !participant.xp_award_date) or course_name
      @level = Reward.find(:first, :conditions=>["xp <= ? and object_type = 'level'",  profile.xp], :order=>"xp DESC")
      puts"#{@level.inspect}"
      profile.level = @level.object_id
      wardrobe = Reward.find(:first, :conditions=>["xp <= ? and object_type = 'wardrobe'",  profile.xp], :order=>"xp DESC")
      puts"#{wardrobe.inspect}"
      profile.wardrobe = wardrobe.object_id if wardrobe
    else
      task_grade = TaskGrade.find(:first, :conditions => ["task_id = ? and profile_id = ? and course_id = ? and school_id = ?",task.id,profile.id,task.course_id,profile.school_id])
      profile.xp -= task_grade.points if participant.xp_award_date and task_grade
    end
    profile.save
    if( profile.xp > previous_points)
      content = "Congratulations! You have received #{award_points} XP for #{task.name}." unless course_name
      content = "Congratulations! You have received #{award_points} Final Bonus Points for #{course_name}." if course_name
      Message.send_notification(current_user,content,profile.id)
    end
    if(previous_level != profile.level)
      content = "Congratulations! You have achieved level #{profile.level}."
      Message.send_notification(current_user,content,profile.id)
    end 
    Reward.notification_for_new_reward(profile,current_user) if profile.wardrobe > previous_wardrobe 
  end
  
  def self.points_to_student(task_id, complete, profile_id,current_user)
    status = nil
    participant = TaskParticipant.find(:first,
      :include => [:profile, :task],
      :conditions => ["task_id = ? and profile_id = ?", task_id, profile_id])
    if participant
      profile = participant.profile
      task = participant.task
      remaining_points = task.remaining_points(profile_id)
      
      return status if (remaining_points <= 0 or participant.xp_award_date) and complete
      
      award_points = task.points if remaining_points > task.points
      award_points = remaining_points unless remaining_points > task.points
      if participant.profile_type == Task.profile_type_member
      # Give points to members who completed the task
        Task.award_xp(complete,profile,participant,task,award_points,current_user)
        Task.task_grade_points(task_id,profile_id,complete,award_points)
        participant.xp_award_date = complete ? Time.now : nil
        participant.save
      end
    end
    return status
  end
	
  def remaining_points(profile_id)
    total_points = TaskGrade.sum(:points,
      :conditions => ["course_id = ? and profile_id = ?", self.course.id, profile_id])
    
    return Course.default_points_max - total_points
  end
  
	def task_owner
    if @owner == nil
      @owner = Profile.find(
				:first, 
				:include => [:task_participants], 
				:conditions => ["task_participants.task_id = ? AND task_participants.profile_type = ?", self.id, Task.profile_type_owner]
      )
    end
    return @owner
  end

  def grade_recalculate
    participant_profile_ids = TaskGrade.find(:all, :conditions => ["task_id = ?",self.id]).collect(&:profile_id)
    if participant_profile_ids
      participant_profile_ids.each do |profile_id|
        previous_task_grade = TaskGrade.where("school_id = ? and course_id = ? and task_id =? and profile_id = ? ",self.school_id,self.course_id,self.id,profile_id).first
        if previous_task_grade
          average,previous_grade = TaskGrade.grade_average(self.school_id,self.course_id,profile_id)
          grade = average.round(2).to_s + " " + GradeType.value_to_letter(average, self.school_id) if average
          CourseGrade.save_grade(profile_id, grade, self.course_id,self.school_id)
        end
      end
    end
  end
end
