class Course < ActiveRecord::Base
  include Comparable

  belongs_to :school
  has_many :participants, as: :target
  has_many :messages, as: :parent
  has_many :categories
  has_many :tasks, -> { order 'due_date' }
  # has_many :outcomes
  has_and_belongs_to_many :outcomes
  has_many :attachments, as: :target
  has_attached_file :image,
                    storage: :s3,
                    s3_credentials: { access_key_id: ENV.fetch('S3_KEY', nil),
                                      secret_access_key: ENV.fetch('S3_SECRET', nil) },
                    path: 'schools/:school/courses/:id/:filename',
                    bucket: ENV.fetch('S3_PATH', nil),
                    s3_protocol: ENV.fetch('S3_PROTOCOL', nil)

  has_many :forums, -> { class_name 'Course', conditions { parent_type 'F' }, order => 'name' }
  has_one :wall, as: :parent
  has_one :game

  after_initialize :init_defaults
  after_save :save_messages
  after_save :save_owner

  # Defaults

  @@default_points_max = 1000 # Total XP that a course may give out
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

  @@default_image_file = '/images/course_img_default.jpg'
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
    sort_order = ['Fall', 'Summer II', 'Summer I', 'Spring', 'Winter']
    sort_order.index(semester) <=> sort_order.index(other.semester)
  end

  def image_file
    image_file_name ? image.url : Course.default_image_file
  end

  def init_defaults
    self.rating_low = Course.default_rating_low
    self.rating_medium = Course.default_rating_medium
    self.rating_high = Course.default_rating_high

    self.tasks_low = tasks_low.blank? ? Course.default_tasks_low : tasks_low
    self.tasks_medium = tasks_medium.blank? ? Course.default_tasks_medium : tasks_medium
    self.tasks_high = tasks_high.blank? ? Course.default_tasks_high : tasks_high
  end

  def code_section
    "#{code}#{'-' unless section.blank?}#{section}"
  end

  def semester_year
    return year.to_s if semester.blank?
    return semester.to_s if year.blank?

    "#{semester} #{year}"
  end

  # The number of points that remains unallocated. Sum up the the points for all tasks associated
  # with this course, plus any extra credit, and minus from the max 1000 points.
  def remaining_points
    total_points = Task.sum(:points,
                            conditions: ['course_id = ? and archived = ?', id, false])

    # FIXME: What about rainy-day bucket and extra credit tasks?

    Course.default_points_max - total_points
  end

  def self.is_owner?(course_id, profile_id)
    owner = Profile.where([
                            "participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", course_id
                          ])
                   .includes([:participants])
                   .joins([:participants])
                   .first
    return false if owner.nil?

    owner.id == profile_id
  end

  def owner
    if @owner.nil?
      @owner = Profile.where([
                              "participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", id
                            ])
                     .includes([:participants])
                     .joins([:participants])
                     .first
    end
    @owner
  end

  def owner=(o)
    attributes = { target_type: 'Course', profile_type: 'M', target_id: id }
    if p = Participant.where(attributes).first
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
    @messages ||= Message.where({ target_id: id,
                                  target_type: parent_type }).order('starred DESC, created_at DESC')
  end

  attr_writer :messages

  def save_messages
    # this only really needs to fire when a course is duplicated
    if @messages
      messages.each do |m|
        m.target_type = parent_type || 'C'
        m.target_id = id
        m.parent_type = m.target_type
        m.parent_id = m.target_id

        mv = MessageViewer.new
        mv.poster_profile = owner.profile
        mv.viewer_profile = owner.profile
        m.message_viewers.push mv

        m.save
      end
    end
  end

  def self.get_top_achievers(school_id, course_id, outcome_id)
    member_ids = Profile.where(["participants.target_id = ? AND participants.profile_type IN ('P', 'S')", course_id])
                        .includes([:participants])
                        .joins([:participants])
                        .map(&:id)
    @students = CourseGrade.where(
      "school_id = ? and course_id = ? and outcome_id = ? and grade >= '2.1' and profile_id in (?)", school_id, course_id, outcome_id, member_ids
    ).order('grade DESC')
    sorted_gpa = Course.sort_top_achievers(@students, school_id, course_id, 'GPA')
    sorted_total_xp = Course.sort_top_achievers(sorted_gpa, school_id, course_id, 'XP')
    sorted_total_xp.uniq[0..4]
  end

  # Returns the total XP assigned for the course (in Tasks)
  def get_xp
    Task.where(course_id: id, archived: false).sum(:points)
  end

  def get_participants
    course_id = id

    # Find all people in the course, including teachers.
    # profile_type: 'M'oderator, 'S'tudent
    Profile.joins(:participants)
           .where(participants: {
                    target_id: course_id,
                    target_type: 'Course'
                  })
  end

  # Get the gaming activity of the students in CVS firmat.
  # This will include all activities later, e.g. posts
  def get_activity_csv
    row = []

    profiles = get_participants

    CSV.generate do |csv|
      row << 'Player'
      row << 'Course'
      row << 'Course Number'
      row << 'Semester'
      row << 'Year'
      row << 'Game'
      row << 'Total Time'
      row << 'XP'
      # row << "Correct Answer #"
      # row << "Incorrect Answer #"
      row << 'Current Level'
      row << 'Score'
      row << 'Badge #'

      csv << row

      # Student Name
      # Course Name
      # Course Number
      # Semester
      # Year
      # One column for each successful login: Show date stamp, time spent, and highest score per login
      # Time spent overall
      # XP
      # Number of correct and incorrect answers
      # Current Level
      # Highest Score
      # Number of Badges
      # One column for each outcome: Show rating

      course = self

      profiles.each do |profile|
        # What are the courses that you teach, if any?
        # @outcome_ratings = @game.list_outcome_ratings(profile.id)
        # @ratings = {}
        # @outcome_ratings.each do | outcome, rating |
        #   @ratings[outcome.id] = rating
        # end

        games = profile.get_games

        games.each do |game|
          row = []

          row << profile.full_name
          row << course.name
          row << course.code_section
          row << course.semester
          row << course.year
          row << game.name
          row << Time.at(game.get_duration(profile.id)).utc.strftime('%H:%M')
          row << profile.xp_by_game(game.id)
          row << game.get_level(profile.id)
          row << game.get_score(profile.id)
          row << game.get_badge_count(profile.id)

          outcome_ratings = game.list_outcome_ratings(profile.id)
          ratings = {}
          outcome_ratings.each do |outcome, rating|
            ratings[outcome.id] = rating
          end

          outcome_list = game.outcomes
          outcome_list.each do |outcome|
            row << "#{outcome.name}: #{ratings[outcome.id]}" unless outcome.name.blank?
          end

          csv << row
        end
      end
    end
  end

  def self.sort_top_achievers(students, school_id, course_id, sort_type)
    sorted_array = []
    outcome_grades = students.map(&:grade)
    profile_ids = students.map(&:profile_id)
    temp = 0
    outcome_grades.each_with_index do |_og, i|
      next unless i >= temp

      count = outcome_grades.count(outcome_grades[i])
      temp += count
      if count > 1
        if sort_type == 'GPA'
          course_grades = CourseGrade.where(
            'school_id = ? and course_id = ? and profile_id in (?) and outcome_id is null and grade is not null', school_id, course_id, profile_ids[i..count + i - 1]
          ).order('grade DESC')
          sorted_array.concat(course_grades)
          p_ids = profile_ids[i..count + i - 1]
          c_ids = course_grades.map(&:profile_id)
          remaining_people = p_ids - c_ids
          if remaining_people.count > 0
            remaining_people.each do |people|
              sorted_array.push(students[profile_ids.find_index(people)])
            end
          end
        else
          profiles = Profile.where(['id in (?)', profile_ids[i..count + i - 1]])
                            .order('xp desc')
          sorted_array.concat(profiles)
        end
      else
        sorted_array.push(students[i]) if sort_type == 'GPA'
        sorted_array.push(students[i].profile) if sort_type == 'XP'
      end
    end
    sorted_array
  end

  def self.all_group(profile, filter)
    if filter == 'M'
      @courses = Course.where([
                                'removed = ? and participants.profile_id = ? AND parent_type = ? AND participants.profile_type != ? AND courses.archived = ?', false, profile.id, Course.parent_type_group, Course.profile_type_pending, false
                              ])
                       .distinct
                       .includes([:participants])
                       .order('courses.name')
                       .joins([:participants])
    else
      @courses = Course.where(['removed = ? AND parent_type = ? AND school_id = ?', false, Course.parent_type_group,
                               profile.school_id])
                       .order('courses.name')
    end
    @courses
  end

  def self.course_filter(profile_id, filter)
    archived = if ['active', ''].include?(filter)
                 false
               else
                 true
               end
    @courses = Course.where(
      [
        'removed = ? and participants.profile_id = ? AND parent_type = ? AND join_type = ? AND participants.profile_type != ? AND courses.archived = ?', false, profile_id, Course.parent_type_course, Course.join_type_invite, Course.profile_type_pending, archived
      ]
    ).order('courses.name')
                     .joins(:participants, :school)
                     .includes(:participants, :school)
                     .distinct
    @courses
  end

  def self.hexdigest_to_string(string)
    string.unpack('U' * string.length).collect { |x| x.to_s 16 }.join
  end

  def self.hexdigest_to_digest(hex)
    hex.unpack('a2' * (hex.size / 2)).collect { |i| i.hex.chr }.join
  end

  def self.sort_course_task(course_id)
    @tasks = []
    task_ids = Task.where([
                            'tasks.course_id = ? and tasks.archived = ? and (tasks.category_id is null or tasks.category_id = ?)', course_id, false, 0
                          ])
                   .includes([:category])
                   .order('tasks.due_date,tasks.created_at')
                   .map(&:id)
    categorised_task_ids = Task.where(['tasks.course_id = ? and categories.course_id = ? and tasks.archived = ?',
                                       course_id, course_id, false])
                               .includes([:category])
                               .order('percent_value,categories.name,due_date,tasks.created_at')
                               .joins([:category])
                               .map(&:id)
    task_ids.concat(categorised_task_ids)
    task_ids.each do |task_id|
      @tasks.push(Task.find(task_id))
    end
    @tasks
  end

  def self.search(text)
    d = text.downcase
    Course.where([
                   '(lower(courses.name) LIKE ? OR lower(courses.code) LIKE ?) and parent_type = ? and school_id = ? and removed = ?', d, d, Course.parent_type_course, @profile.school_id, false
                 ])
  end

  def course_forum(profile_id = nil)
    Course.where(['participants.profile_id = ? AND course_id = ? AND archived = ? AND removed = ?',
                  profile_id, id, false, false])
          .includes([:participants])
          .order('courses.name')
          .joins([:participants])
  end

  # Returns the latest messages for this course
  def find_game_messages(profile_id = nil)
    course_id = id
    parent_type = 'G'

    if profile_id.nil?
      return Message.where(messages: { parent_id: course_id, parent_type: parent_type })
                    .order('messages.starred DESC', 'messages.post_date DESC')
                    .limit(200)
    end

    # This is not efficient because it will query each message individually
    MessageViewer.joins(:message)
                 .where(viewer_profile_id: profile_id,
                        messages: { parent_id: course_id, parent_type: parent_type })
                 .order('messages.starred DESC', 'messages.post_date DESC')
                 .limit(200)
                 .collect(&:message)
  end

  def join_all(profile)
    @all_members = Profile.where([
                                   "participants.target_id = ? AND participants.target_type in ('Course','Group') AND participants.profile_type IN ('M', 'S')", course_id
                                 ])
                          .includes([:participants])
                          .joins([:participants])
    if @all_members and !@all_members.nil?
      @all_members.each do |viewer|
        participant_exist = Participant.where(["target_id = ? AND target_type = 'Course' AND profile_id = ?", id,
                                               viewer.id]).first
        next if participant_exist

        @participant = Participant.new
        @participant.target_id = id
        @participant.target_type = 'Course'
        @participant.profile_id = viewer.id
        @participant.profile_type = 'S'
        next unless @participant.save

        wall_id = Wall.get_wall_id(id, 'Course')
        Feed.create(
          profile_id: viewer.id,
          wall_id: wall_id
        )
        course = Course.find(course_id)
        content = "#{profile.full_name} added you to a new forum in #{course.name} #{course.section}: #{name}"
        Message.send_notification(profile.id, content, viewer.id)
      end
    end
  end

  def duplicate(params = {}, current_user = nil)
    categories = {}
    outcomes = {}

    duplicate = dup
    duplicate.owner = owner
    duplicate.wall = wall.dup if wall

    if params[:name_ext]
      name = "#{duplicate.name} #{params[:name_ext]}"
      duplicate.name = name
      i = 0

      while existing = Course.where({ name: duplicate.name, archived: false, removed: false }).first
        i += 1
        duplicate.name = "#{name}#{i}"
      end
    end

    self.outcomes.each do |outcome|
      outcomes[outcome.id] ||= outcome.dup
      duplicate.outcomes << outcomes[outcome.id]
    end

    begin
      duplicate.image = image
    rescue StandardError
      logger.error "AWS::S3::NoSuchKey: #{image.url}"
    end

    self.categories.each do |category|
      categories[category.id] ||= category.dup
      duplicate.categories << categories[category.id]
    end

    course_forum(owner.id).each do |forum|
      duplicate.forums.push forum.duplicate
    end

    messages.where(starred: true, archived: false, profile_id: owner.id).each do |message|
      m = message.dup
      m.wall = duplicate.wall
      m.like = 0
      duplicate.messages.push m
    end

    attachments.each do |attachment|
      next unless attachment.owner == duplicate.owner.profile

      a = Attachment.new

      a.target = duplicate
      a.school = attachment.school
      a.owner = attachment.owner
      a.starred = attachment.starred

      begin
        a.resource = attachment.resource
      rescue StandardError
        # a.resource = nil
        logger.error "AWS::S3::NoSuchKey: #{attachment.resource.url}"
      end

      duplicate.attachments << a
    end

    tasks.each do |task|
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
        next unless attachment.owner == duplicate.owner.profile

        a = Attachment.new

        a.target = t
        a.school = attachment.school
        a.owner = attachment.owner
        a.starred = attachment.starred

        begin
          a.resource = attachment.resource
        rescue StandardError
          # a.resource = nil
          logger.error "AWS::S3::NoSuchKey: #{attachment.resource.url}"
        end

        t.attachments << a
      end

      task.task_participants.each do |task_participant|
        next unless task_participant.profile_type == 'O'

        tp = task_participant.dup
        tp.task = t
        tp.status = Task.status_assigned
        tp.complete_date = nil
        t.task_participants << tp
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
      joins: [:profile],
      conditions: [
        "participants.target_id=? AND participants.profile_type = 'S' AND target_type = 'Course'", id
      ],
      select: [
        'profiles.full_name,participants.id,participants.profile_id'
      ]
    )
    @participant.each do |p|
      TaskGrade.bonus_points(p.profile.school_id, self, p.profile.id, current_profile.id)
      outcomes_grade = []
      next if @outcomes.nil?

      @outcomes.each do |o|
        outcome_grade = CourseGrade.load_outcomes(p.profile_id, id, o.id, current_profile.school_id)
        next unless !outcome_grade.blank? and outcome_grade >= 2.5

        @badge = Badge.gold_outcome_badge(o.name, current_profile)
        if @badge
          avatar_badge = AvatarBadge.where([
                                             'profile_id = ? and badge_id = ? and course_id = ? and giver_profile_id = ?', p.profile_id, @badge.id, id, current_profile.id
                                           ]).first
        end
        status = AvatarBadge.add_badge(p.profile_id, @badge.id, id, current_profile.id) if avatar_badge.nil?
      end
    end
    Pusher["course-finalize-#{current_profile.user.id}"].trigger('complete', { status: status })
  end

  def self.all_archived_courses_by_school(school_id)
    where(['archived = ? and removed = ? and parent_type = ? and name is not null and school_id = ?', true, false,
           Course.parent_type_course, school_id])
      .order('name')
      .distinct
  end

  def self.all_courses_by_school(school_id)
    where(['archived = ? and removed = ? and parent_type = ? and name is not null and school_id = ?', false, false,
           Course.parent_type_course, school_id])
      .distinct
      .order('name')
  end

  def self.all_groups_by_school(school_id)
    where(['archived = ? and removed = ? and parent_type = ? and name is not null and school_id = ?', false, false,
           Course.parent_type_group, school_id])
      .distinct
      .order('name')
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
      courses = if semester == 'All'
                  Course.where(id: all_course_ids, year: year.to_i,
                               semester: Course.pluck(:semester).compact.uniq)
                elsif semester == 'Summer'
                  Course.where(id: all_course_ids, year: year.to_i, semester: semester + ' ' + seq_semester)
                else
                  Course.where(id: all_course_ids, year: year.to_i, semester: semester)
                end
      courses.try(:order, 'updated_at DESC')
    end
  end
end
