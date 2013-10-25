task :recalculate_outcome_grades => :environment do
  outcome_averages = CourseGrade.where("outcome_id IS NOT NULL")
  outcome_averages.each do |o|
    outcome_grades = OutcomeGrade.where(
      :school_id => o.school_id,
      :course_id => o.course_id,
      :outcome_id => o.outcome_id,
      :profile_id => o.profile_id
    )

    unless outcome_grades.count == 0
      grades = outcome_grades.map(&:grade).compact

      if grades.count == 0
        o.grade = 0
      else 
        o.grade = grades.inject(0, :+).to_f / grades.count
      end

      o.save
    end
  end
end

task :recalculate_task_grades => :environment do
  course_grades = CourseGrade.where("outcome_id IS NULL")

  course_grades.each do |cg|
    flag = false
    average = 0
    category_used = 0
    tasks = Task.find(:all,:conditions => ["school_id = ? and course_id = ? and archived = false", cg.school_id, cg.course_id])
    c = Category.find(:all,:conditions => ["course_id = ?", cg.course_id])
    categories = c.map do |category|
      {:id => category.id, :percent_value => category.percent_value, :count => 0}
    end

    tasks.each do |task|
      if task.category
        tg = TaskGrade.find(:first,:conditions => ["school_id = ? and course_id = ? and task_id =? and profile_id = ?", cg.school_id, cg.course_id, task.id, cg.profile_id])
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
        tg = TaskGrade.find(:first,:conditions => ["school_id = ? and course_id = ? and task_id =? and profile_id = ?", cg.school_id, cg.course_id, task.id, cg.profile_id])
        if tg and tg.grade
          category_index = categories.index{|category| task.category.id == category[:id]}
          percent_share = categories[category_index][:percent_share]
          average += tg.grade * percent_share / category_used unless category_used == 0
          flag = true
        end
      end
    end
    
    cg.grade = flag ? average : nil
    puts cg.grade.to_s
    cg.save
  end
end