class TaskGrade < ActiveRecord::Base
  belongs_to :task

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
    xp_could_get = Task.filter_by(profile_id,course.id,"").collect(&:points).sum
    xp_could_get = Course.default_points_max if xp_could_get > Course.default_points_max
    bonus_points = received_xp / xp_could_get.to_f * Course.default_points_max - received_xp
    task_grade = TaskGrade.where(:school_id => school_id, :profile_id => profile_id, :course_id => course.id, :task_id => nil).first
    if task_grade.nil?
      task_grade = TaskGrade.create({:school_id => school_id, :course_id => course.id, :profile_id => profile_id, :points => bonus_points})
      profile = Profile.find(profile_id)
      Task.award_xp(true,profile,nil,task_grade,task_grade.points,current_user,course.name)
    end
  end

  def self.grade_average(school_id,course_id,profile_id,task_id = nil,task_grade = nil)
    average = 0
    flag = false
    category_count = []
    category_percent_value = []
    category_used = 0
    tasks = Task.find(:all,:conditions => ["course_id = ? and archived = false",course_id])
    categories = Category.find(:all,:conditions => ["course_id = ?",course_id]).collect(&:percent_value)
    categories.each_with_index do |category,i|
      category_count[i] = 0
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
        tg = TaskGrade.find(:first,:conditions => ["school_id = ? and course_id = ? and task_id =? and profile_id = ?",school_id,course_id,task.id,profile_id])
        if tg and tg.grade
          category_count[categories.find_index(task.category.percent_value)] += 1
          category_used += task.category.percent_value if category_count[categories.find_index(task.category.percent_value)] == 1
        end
      end
    end
    category_count.each_with_index do |count,j|
      category_percent_value[j] = categories[j]/count.to_f unless count == 0
      category_percent_value[j] = 0 if count == 0
    end
    tasks.each do |task|
      if task.category
        tg = TaskGrade.find(:first,:conditions => ["school_id = ? and course_id = ? and task_id =? and profile_id = ?",school_id,course_id,task.id,profile_id])
        if tg and tg.grade
          average += tg.grade*category_percent_value[categories.find_index(task.category.percent_value)]/category_used unless category_used == 0
          flag = true
        end
      end
    end
    return average,previous_grade if flag
    return nil,previous_grade
  end

end
