class TaskGrade < ActiveRecord::Base
  belongs_to :task

  def self.task_grades(school_id,course_id,task_id, profile_id,task_grade,grade)
    @grade= TaskGrade.where("school_id = ? and course_id = ? and task_id =? and profile_id = ? ",school_id,course_id,task_id,profile_id).first
    CourseGrade.save_grade(profile_id, grade, course_id, school_id)
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
    tg = GradeType.is_num(task_grade.to_s) ? task_grade : GradeType.letter_to_value(task_grade, 1)
    grade = grade_obj.grade
    grade_obj.update_attribute('grade', tg)
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
    xp = self.select("sum(points) as total").where(
      "school_id = ? and course_id = ? and profile_id = ?",
      school_id,course.id,profile_id
    ).group("task_grades.id")
    received_xp = xp.first.total.to_i if !xp.first.nil? else 0

    tasks = Task.filter_by(profile_id,course.id,"")
    xp_could_get = Task.filter_by(profile_id,course.id,"").collect(&:points).sum
    xp_could_get = Course.default_points_max if xp_could_get > Course.default_points_max
    bonus_points = received_xp / xp_could_get.to_f * Course.default_points_max - received_xp unless xp_could_get == 0
    task_grade = TaskGrade.where(:school_id => school_id, :profile_id => profile_id, :course_id => course.id, :task_id => nil).first
    if task_grade.nil?
      task_grade = TaskGrade.create({:school_id => school_id, :course_id => course.id, :profile_id => profile_id, :points => bonus_points})
      profile = Profile.find(profile_id)
      Task.award_xp(true,profile,nil,task_grade,task_grade.points,current_user,course.name) if task_grade.points
    end
  end

  def self.grade_average(school_id,course_id,profile_id,task_id = nil,task_grade = nil)
    average = 0
    flag = false
    category_percent_value = []
    category_used = 0
    tasks = Task.where(["course_id = ? and archived = false",course_id])
    c = Category.where(["course_id = ?",course_id])
    categories = c.map do |category|
      {:id => category.id, :percent_value => category.percent_value, :count => 0}
    end
    previous_task_grade = TaskGrade.where("school_id = ? and course_id = ? and task_id =? and profile_id = ? ",school_id,course_id,task_id,profile_id).first if task_id
    previous_grade = previous_task_grade.grade if previous_task_grade
    previous_grade = previous_grade.to_f if previous_grade
    if !previous_task_grade.nil? and task_id
      TaskGrade.task_grade_update(task_grade,previous_task_grade)
    else
      TaskGrade.task_grade_save(school_id,course_id,task_id, profile_id,task_grade) if task_id
    end
    tasks.each do |task|
      if task.category
        tg = TaskGrade.where(["school_id = ? and course_id = ? and task_id =? and profile_id = ?",school_id,course_id,task.id,profile_id]).first
        if tg and tg.grade
          category_index = categories.index{|category| task.category.id == category[:id]}
          category = categories[category_index]
          category[:count] += 1
          category_used += task.category.percent_value if category[:count] == 1
        end
      end
    end
    categories.each do |category|
      if category[:count] == 0
        category[:percent_share] = 0
      else
        category[:percent_share] = category[:percent_value] / category[:count].to_f unless category[:count] == 0
      end
    end
    tasks.each do |task|
      if task.category
        tg = TaskGrade.where(["school_id = ? and course_id = ? and task_id =? and profile_id = ?",school_id,course_id,task.id,profile_id]).first
        if tg and tg.grade
          category_index = categories.index{|category| task.category.id == category[:id]}
          percent_share = categories[category_index][:percent_share]
          average += tg.grade * percent_share / category_used unless category_used == 0
          flag = true
        end
      end
    end
    return average,previous_grade if flag
    return nil,previous_grade
  end
  
  def self.sort_tasks_grade(profile_id, course_id)
    graded_tasks_ids = TaskGrade.where( [ "task_grades.course_id = ? and task_grades.profile_id = ? and task_grades.grade IS NOT NULL and tasks.archived = 'false'", course_id, profile_id ])
      .include([:task])
      .joins([:task])
      .map(&:task_id)
    return graded_tasks_ids
  end
  

end
