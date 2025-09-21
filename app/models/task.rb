class Task < ActiveRecord::Base
  has_many :group
  belongs_to :category
  belongs_to :school
  belongs_to :task
  belongs_to :course
  belongs_to :group
  has_many :task_participants
  has_many :participants, as: :target
  has_many :attachments, as: :target
  has_many :messages, as: :parent
  has_many :outcome_tasks
  has_many :outcomes, through: :outcome_tasks

  attr_accessor :task_outcomes, :task_category

  after_initialize :init_defaults
  after_create :image_save

  has_attached_file :image,
                    storage: :s3,
                    s3_credentials: { access_key_id: ENV.fetch('S3_KEY', nil),
                                      secret_access_key: ENV.fetch('S3_SECRET', nil) },
                    path: 'schools/:school/courses/:course/tasks/:id/:filename',
                    bucket: ENV.fetch('S3_PATH', nil),
                    s3_protocol: ENV.fetch('S3_PROTOCOL', nil)

  @@levels = %w[Low Medium High]
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
    # self.level = 0
  end

  def image_file
    image_file_name ? image.url : Course.default_image_file
  end

  def image_save
    image.save
  end

  def outcomes
    OutcomeTask.where(['task_id = ?', id]).collect { |x| x.outcome }
  end

  def show_date_format(the_date)
    the_date.strftime('%d/%m/%Y')
  end

  def self.filter_by(profile_id, filter, period)
    conditions = ['task_participants.profile_id = ? and archived = ?', profile_id, false]

    if filter == 'starred'
      conditions[0] += ' and task_participants.priority = ?'
      conditions << 'H'
    elsif !filter.to_s.empty?
      conditions[0] += ' and course_id = ?'
      conditions << filter.to_i
    end

    if period == 'current'
      conditions[0] += ' and task_participants.complete_date is null'
    elsif period == 'past'
      conditions[0] += ' and task_participants.complete_date is not null'
    end

    tasks = Task.where(conditions)
                .includes([:task_participants])
                .order('priority asc,due_date')
                .joins([:task_participants])
  end

  def self.search_tasks(profile_id, search_text, filter, course_id)
    conditions = [
      'task_participants.profile_id = ? AND (lower(tasks.name) LIKE ? OR lower(tasks.descr) LIKE ?) AND archived = ?', profile_id, search_text.downcase, search_text.downcase, false
    ]

    if course_id == 'starred'
      conditions[0] += ' AND task_participants.priority = ?'
      conditions << 'H'
    elsif !course_id.blank?
      conditions[0] += ' AND course_id = ?'
      conditions << course_id
    end

    if filter == 'current'
      conditions[0] += ' AND task_participants.complete_date IS NULL'
    elsif filter == 'past'
      conditions[0] += ' AND task_participants.complete_date IS NOT NULL'
    end

    Task.where(conditions)
        .includes([:task_participants])
        .order('priority asc, due_date')
        .joins([:task_participants])
  end

  def self.sort_tasks(profile_id, course_id)
    @tasks = []
    task_ids = Task.where([
                            'tasks.course_id = ? and task_participants.profile_id = ? and tasks.archived = ? and (tasks.category_id is null or tasks.category_id = ?)', course_id, profile_id, false, 0
                          ])
                   .includes(%i[category task_participants])
                   .order('tasks.due_date,tasks.created_at')
                   .joins([:task_participants])
                   .map(&:id)
    categorised_task_ids = Task.where([
                                        'tasks.course_id = ? and task_participants.profile_id = ? and categories.course_id = ? and tasks.archived = ?', course_id, profile_id, course_id, false
                                      ])
                               .includes(%i[category task_participants])
                               .order('percent_value,categories.name,due_date,tasks.created_at')
                               .joins([:task_participants])
                               .map(&:id)

    grade_tasks_ids = TaskGrade.sort_tasks_grade(profile_id, course_id)
    task_ids = task_ids.concat(categorised_task_ids).concat(grade_tasks_ids).uniq
    task_ids.each do |task_id|
      @tasks.push(Task.find(task_id))
    end
    @tasks
  end

  # Calculate the point value of this task based on the task rating and the task estimate counts
  # in the associated course. Each course is allocated a total of 1000 points that are distributed
  # to all the tasks associated with the course. The amount of points is also weighted by the task
  # raiting.
  def calc_point_value
    return 0 if course.nil?
    return 0 if level.nil? or level > 2 or level < 0

    estimated_tasks = course.tasks_low if level == 0
    estimated_tasks = course.tasks_medium if level == 1
    estimated_tasks = course.tasks_high if level == 2
    # level = 0,1,2
    rating_ratio = [course.rating_low, course.rating_medium, course.rating_high]

    # Calculate how many units in total are estimated for the course
    total_units = course.rating_low + course.rating_medium + course.rating_high

    # Calculate how much one unit is worth in terms of XP
    unit = course.default_points_max / total_units.to_f

    # Calculate how much XP this task should be allocated. We will need to track how much points
    # have been allocated to the course over the life of the course. If the allocated points is over
    # the max (1000 points), then no more points can be allocated to tasks for this course.
    all_tasks = Task.filter_by(course.owner.id, course.id, '').collect(&:level)
    new_estimated_tasks = all_tasks.count(level)
    suggested_points = if new_estimated_tasks > estimated_tasks
                         unit * rating_ratio[level] / new_estimated_tasks
                       else
                         unit * rating_ratio[level] / estimated_tasks
                       end
    self.points = suggested_points
  end

  def rating_icon_file
    "/images/ui/task_rating_#{level}.png"
  end

  # Mark the task as complete and give points
  def self.complete_task(task_id, complete, profile_id)
    status = nil
    participant = TaskParticipant.where(['task_id = ? and profile_id = ?', task_id, profile_id])
                                 .includes(%i[profile task])
    return status if participant.nil?

    profile = participant.profile
    task = participant.task

    if participant.profile_type == Task.profile_type_owner
      # If the owner marks the task as complete, we need to close out the task for all members,
      # and mark it incomplete for them. Owner does not get points. There is no going back on this action.
      participant.complete_date = complete ? Time.now : nil
      participant.status = complete ? Task.status_complete : Task.status_assigned
      participant.save
      # participants = TaskParticipant.find(:all,
      # :include => [:profile, :task],
      # :conditions => ["task_id = ? and profile_type = ? and status <> ?", task_id, Task.profile_type_member, Task.status_complete])
      # participants.each do |a_participant|
      # a_participant.complete_date = Time.now
      # a_participant.status = Task.status_incomplete
      # a_participant.save
      # end
      # Task.task_grade_points(task_id,profile_id,complete)
      status = true
    elsif participant.profile_type == Task.profile_type_member
      participant.complete_date = complete ? Time.now : nil
      # if  participant.status ==  Task.status_complete
      # profile.xp += complete ? task.points : -task.points
      # end
      participant.status = complete ? Task.status_complete : Task.status_assigned
      participant.save
      # profile.save
      status = complete
    end
    status
  end

  def self.task_grade_points(task_id, profile_id, complete, award_points)
    @task = Task.find(task_id)
    @task_grade = TaskGrade.where('task_id = ? and profile_id = ?', task_id, profile_id)
    if @task_grade.blank?
      @task_grade << TaskGrade.new({ school_id: @task.school_id, course_id: @task.course_id, task_id: task_id,
                                     profile_id: profile_id })
    end
    unless @task_grade.nil?
      @task_grade.each do |t|
        t.points = complete ? award_points : nil
        t.save
      end
    end
  end

  def self.award_xp(complete, profile, participant, task, award_points, current_user, course_name = nil)
    previous_level = profile.level
    previous_points = profile.xp
    previous_wardrobe = profile.wardrobe
    if complete
      profile.xp += award_points if (participant and !participant.xp_award_date) or course_name
      @level = Reward.where(["xp <= ? and target_type = 'level'",  profile.xp])
                     .order('xp DESC')
                     .first
      puts @level.inspect.to_s
      profile.level = @level.target_id
      wardrobe = Reward.where(["xp <= ? and target_type = 'wardrobe'", profile.xp])
                       .order('xp DESC')
                       .first
      puts wardrobe.inspect.to_s
      profile.wardrobe = wardrobe.target_id if wardrobe
    else
      task_grade = TaskGrade.where(['task_id = ? and profile_id = ? and course_id = ? and school_id = ?', task.id,
                                    profile.id, task.course_id, profile.school_id]).first
      profile.xp -= task_grade.points if participant.xp_award_date and task_grade
    end
    profile.save
    if profile.xp > previous_points
      content = "Congratulations! You have received #{award_points} XP for #{task.name}." unless course_name
      if course_name
        content = "Congratulations! You have received #{award_points} Final Bonus Points for #{course_name}."
      end
      Message.send_notification(current_user, content, profile.id)
    end
    if previous_level != profile.level
      content = "Congratulations! You have achieved level #{profile.level}."
      Message.send_notification(current_user, content, profile.id)
    end
    Reward.notification_for_new_reward(profile, current_user) if profile.wardrobe > previous_wardrobe
  end

  def self.points_to_student(task_id, complete, profile_id, current_user)
    status = nil
    participant = TaskParticipant.where(['task_id = ? and profile_id = ?', task_id, profile_id])
                                 .includes(%i[profile task])
    if participant
      profile = participant.profile
      task = participant.task
      remaining_points = task.remaining_points(profile_id)

      return status if (remaining_points <= 0 or participant.xp_award_date) and complete

      award_points = task.points if remaining_points > task.points
      award_points = remaining_points unless remaining_points > task.points
      if participant.profile_type == Task.profile_type_member
        # Give points to members who completed the task
        Task.award_xp(complete, profile, participant, task, award_points, current_user)
        Task.task_grade_points(task_id, profile_id, complete, award_points)
        participant.xp_award_date = complete ? Time.now : nil
        participant.save
      end
    end
    status
  end

  def remaining_points(profile_id)
    total_points = TaskGrade.sum(:points,
                                 conditions: ['course_id = ? and profile_id = ?', course.id, profile_id])

    Course.default_points_max - total_points
  end

  def task_owner
    if @owner.nil?
      @owner = Profile.where(['task_participants.task_id = ? AND task_participants.profile_type = ?', id,
                              Task.profile_type_owner])
                      .includes([:task_participants])
                      .joins([:task_participants])
                      .first
    end
    @owner
  end

  def grade_recalculate
    participant_profile_ids = TaskGrade.where(['task_id = ?', id]).collect(&:profile_id)
    if participant_profile_ids
      participant_profile_ids.each do |profile_id|
        previous_task_grade = TaskGrade.where('school_id = ? and course_id = ? and task_id =? and profile_id = ? ',
                                              school_id, course_id, id, profile_id).first
        next unless previous_task_grade

        average, previous_grade = TaskGrade.grade_average(school_id, course_id, profile_id)
        grade = average.round(2).to_s + ' ' + GradeType.value_to_letter(average, school_id) if average
        CourseGrade.save_grade(profile_id, grade, course_id, school_id)
      end
    end
  end

  def as_json(options = {})
    # just in case someone says as_json(nil) and bypasses
    # our default...
    super((options || {}).merge({
                                  methods: %i[
                                    task_category
                                    task_outcomes
                                  ]
                                }))
  end
end
