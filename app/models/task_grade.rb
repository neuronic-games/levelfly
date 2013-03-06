class TaskGrade < ActiveRecord::Base
  belongs_to :task
  validates :task_id, :uniqueness => {:scope => :profile_id}

  def self.task_grades(school_id,course_id,task_id, profile_id,task_grade,grade)
    @grade= TaskGrade.where("school_id = ? and course_id = ? and task_id =? and profile_id = ? ",school_id,course_id,task_id,profile_id).first
    CourseGrade.save_grade(profile_id, grade, course_id)
    if !@grade.nil?
      self.task_grade_update(task_grade,@grade)
    else
      self.task_grade_save(school_id,course_id,task_id, profile_id,task_grade)
    end
  end

  def self.task_grade_save(school_id,course_id,task_id, profile_id,task_grade)
    #grade = GradeType.letter_to_value(task_grade, school_id)
    @task_grade = TaskGrade.new
    @task_grade.school_id = school_id
    @task_grade.course_id = course_id
    @task_grade.task_id = task_id
    @task_grade.profile_id = profile_id
    @task_grade.grade = task_grade
    @task_grade.save
    return ""
  end
  
  def self.task_grade_update(task_grade,grade_obj)
    grade = grade_obj.grade
    grade_obj.update_attribute('grade',task_grade)
    return grade
  end
  
  def self.load_task_grade(school_id, course_id,task_id,profile_id)
    task_grade = TaskGrade.where("school_id = ? and course_id = ? and task_id = ? and profile_id = ?",school_id, course_id,task_id,profile_id).first
    if task_grade.nil?
      return nil
    else
      return task_grade.grade 
    end
  end  
  
  def self.bonus_points(school_id,course,profile_id,current_user)
    xp = self.select("sum(points) as total").where("school_id = ? and course_id = ? and profile_id = ?",school_id,course.id,profile_id)
    received_xp = xp.first.total.to_i
    tasks = Task.filter_by(profile_id,course.id,"")
    tasks.each do |task|
      task.update_attribute('points',task.calc_point_value) if task.points == 0
    end
    xp_could_get = Task.filter_by(profile_id,course.id,"").collect(&:points).sum
    xp_could_get = Course.default_points_max if xp_could_get > Course.default_points_max
    bonus_points = received_xp / xp_could_get.to_f * Course.default_points_max - received_xp
    task_grade = TaskGrade.where(:school_id => school_id, :profile_id => profile_id, :course_id => course.id, :task_id => nil).first
    if task_grade.nil?
      task_grade = TaskGrade.create({:school_id => school_id, :course_id => course.id, :profile_id => profile_id, :points => bonus_points})
      profile = Profile.find(profile_id)
      Task.award_xp(true,profile,nil,task_grade,bonus_points,current_user,course.name)
    end
  end

end
