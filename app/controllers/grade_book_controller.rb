require 'csv'

class GradeBookController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  include GradeBookHelper

  def index
    @enable_palette = false
    @profile = current_profile
    if @profile
      setting = Setting.find(:first, :conditions=>["target_id = ? and value = 'true' and target_type ='school' and name ='enable_grade_palette' ",@profile.school_id])
      if setting and !setting.nil?
        @enable_palette = true
      end
      filter_course("active")
    end
    respond_to do |wants|
      wants.html do
        @data = {
          :tasks => Course.sort_course_task(@course_id),
          :categories => Category.all(:conditions => {:course_id => @course_id, :school_id => @school_id}),
          :participant => Participant.all( :joins => [:profile => :user],
            :conditions => ["participants.target_id = ? AND participants.profile_type = 'S' AND target_type = 'Course' AND users.status != 'D'", @course_id],
            :select => ["profiles.full_name,participants.id,participants.profile_id"],
            :order => "full_name"
            ),
          :grade_types => GradeType.order("value DESC"),
          :task_grades => TaskGrade.all(:conditions => { :course_id => @course_id, :school_id => @school_id })
        }

        if request.xhr?
          render :partial => "/grade_book/list"
        else
          render
        end
      end
    end
  end


  def filter_course(filter)
    if filter =="past"
      archived = true
    else
      archived = false
    end
    @profile = current_profile
    @courses = [];
    unsorted_courses = [];
    @people =[];
    @tasks = [];
    @latest_course = nil
    course_list = Course.find(
      :all,
      :select => "distinct *",
      :include => [:participants],
      :conditions => ["removed = ? and participants.profile_id = ? AND parent_type = ? AND participants.profile_type = ? AND courses.archived = ?",false, @profile.id, Course.parent_type_course, Course.profile_type_master, archived],
      :order => 'courses.name ASC'
      )
    course_list.each do |c|
      if c.participants.find(:all, :conditions=>["profile_type in ('M','S')"]).count>1
        unsorted_courses.push(c)
      end
    end

    @courses = unsorted_courses.sort
    
    if @courses.length > 0
      @school_id = @profile.school_id
      @latest_course = @courses.first
      @course_id = @latest_course.id
      @outcomes = @latest_course.outcomes
      @participant = Participant.all( :joins => [:profile => :user], :conditions => ["participants.target_id=? AND participants.profile_type = 'S' AND target_type = 'Course' AND users.status != 'D'",@course_id],:select => ["profiles.full_name,participants.id,participants.profile_id"], :order => "full_name")
      #@participant = @courses.first.participants
      @count = @participant.count
      @tasks = Course.sort_course_task(@course_id)
    end
  end

    def filter
      if params[:filter] && !params[:filter].blank?
        filter_course(params[:filter])

        @data = {
          :tasks => Course.sort_course_task(@course_id),
          :categories => Category.all(:conditions => {:course_id => @course_id}),
          :participant => Participant.all( :joins => [:profile => :user],
            :conditions => ["participants.target_id = ? AND participants.profile_type = 'S' AND target_type = 'Course' AND users.status != 'D'", @course_id],
            :select => ["profiles.full_name,participants.id,participants.profile_id"],
            :order => "full_name"
            ),
          :grade_types => GradeType.order("value DESC"),
          :task_grades => TaskGrade.all(:conditions => { :course_id => @course_id })
        }

        render :partial => "/grade_book/load_data"
      end
    end

    def get_task
      if params[:course_id] && !params[:course_id].blank?
        @profile = Profile.find(user_session[:profile_id])
        @course = Course.find(params[:course_id])
        @categories = Category.all(:conditions => {:course_id => params[:course_id]})
        show_outcomes = @course.show_outcomes if @course
        @outcomes = @course.outcomes.order('name')
        @participant = Participant.all( :joins => [:profile => :user],
          :conditions => ["participants.target_id = ? AND participants.profile_type = 'S' AND target_type = 'Course' AND users.status != 'D'", params[:course_id]],
          :select => ["profiles.full_name,participants.id,participants.profile_id, profiles.image_file_name"],
          :order => "full_name")
        @tasks =  Course.sort_course_task(params[:course_id])
        if not @participant.nil?
          @participant.each do |p|
            outcomes_grade = []
            array_task_grade = []
            array_task_outcome_grade = []
            participant_grade, outcome_grade = CourseGrade.load_grade(p.profile_id, params[:course_id],@profile.school_id)
            if participant_grade.blank?
              p["grade"] = ""
            else
              participant_grade.each do |key, val|
                grade = val.to_s + " " + GradeType.value_to_letter(val, @profile.school_id) if val
                p["grade"] = grade if val
                p["grade"] = "" unless val
              end
            end
            if !@outcomes.nil?
              @outcomes.each do |o|
                outcome_grade = CourseGrade.load_outcomes(p.profile_id, params[:course_id],o.id,@profile.school_id)
                if outcome_grade.nil?
                  outcome_grade=""
                end
                outcomes_grade.push(outcome_grade)
              end
              p["course_outcomes"] = outcomes_grade
            end
            if not @tasks.nil?
              @tasks.each do |t|

                task_grade = TaskGrade.load_task_grade(@profile.school_id, params[:course_id],t.id,p.profile_id)
                grade=""
                if !task_grade.blank?
                  grade = task_grade.to_f if t.course.display_number_grades
                  grade = GradeType.value_to_letter(task_grade, @profile.school_id) unless t.course.display_number_grades
                end
                array_task_grade.push(grade)
                task_outcomes = t.outcomes.sort_by{|a| a.name.downcase}
                task_outcomes.each do |o|
                  task_outcome_grade = OutcomeGrade.load_task_outcomes(@profile.school_id, params[:course_id],t.id,p.profile_id,o.id)
                  if task_outcome_grade.nil?
                    task_outcome_grade=""
                  end
                  array_task_outcome_grade.push(task_outcome_grade)

                end

              end
              p["task_grade"] = array_task_grade
            end

            p["task_outcome_grade"] = array_task_outcome_grade
          end
        end
        @task_outcomes = []
        if not @tasks.nil?
          @tasks.each do |t|
            t["task_outcomes"] = t.outcomes.sort_by{|m| m.name.downcase}
            task = Task.find(t.id)
            t["task_category"] = load_caregory_name(t.id)
          end
        end
        @count = @participant.count
      end

      respond_to do |format|
        format.html
        format.json   {
          render :json =>{
            :tasks => @tasks,
            :participant => @participant,
            :outcomes => @outcomes,
            :categories => @categories,
            :grade_types => GradeType.order("value DESC"),
            :task_grades => TaskGrade.all(:conditions => { :course_id => params[:course_id] }),
            :profile => @profile,
            :count => @count,
            :show_outcomes => show_outcomes}}
          end

        end

   #used for caclulation for grade
   def grade_calculate
    if params[:characters] && !params[:characters].blank?
      characters = params[:characters].split(",") if params[:characters]
      school_id = params[:school_id]
      course_id = params[:course_id]
      course = Course.find(params[:course_id])
      previous_grade_type = course.display_number_grades
      task_id = params[:task_id]
      profile_ids = params[:profile_id].split(",") if params[:profile_id]
      task_grade = params[:task_grade]
      p=profile_ids.length
      arr_grade = []
      arr_previous_grade = []
      arr_task_grade = []
      undo = params[:undo]
      previous_values = params[:last_changes].split(",") if params[:last_changes]
      if undo == "true" and !previous_values.blank?
        previous_values.each do |pg|
          num = GradeType.is_num(pg)
          previous_grade=""
          if num == false
            arr_task_grade.push(GradeType.letter_to_value(pg, school_id))
          end
        end
      else
        num = GradeType.is_num(task_grade)
        previous_grade=""
        if num == false
          task_grade = GradeType.letter_to_value(task_grade, school_id)
          task_grade = task_grade.to_f unless task_grade.nil?
        end
      end

      # Save the grade
      if !profile_ids.nil?
        # Calculate the GPA
        sub_arrays = characters.in_groups(p, false)
        profile_ids.each_with_index do |p,j|
          average,previous_grade = TaskGrade.grade_average(school_id,course_id,p,task_id,task_grade)
          previous_grade = GradeType.value_to_letter(previous_grade, school_id) if !course.display_number_grades and previous_grade
          course.update_attribute('display_number_grades',num) unless task_grade.blank?
          @grade = average.round(2).to_s + " " + GradeType.value_to_letter(average, school_id) if average
          arr_grade.push(@grade)
          arr_previous_grade.push(previous_grade)
          if undo == "true" and !previous_values.blank?
            @grade_task = TaskGrade.task_grades(school_id,course_id,task_id, profile_ids[j],arr_task_grade[j],average)
          else
            @grade_task = TaskGrade.task_grades(school_id,course_id,task_id, profile_ids[j],task_grade,average)
          end
        end
      end
      render :json => {:grade => arr_grade, :previous_grade => arr_previous_grade}
    end
  end


  #save outcome points
  def outcomes_points
    if params[:course_id] && !params[:course_id].blank?
      average = params[:average].split(",") if params[:average]
      school_id = params[:school_id]
      course_id = params[:course_id]
      outcome_id = params[:outcome_id]
      profile_ids = params[:profile_id].split(",") if params[:profile_id]
      task_id = params[:task_id]
      outcome_val = params[:outcome_val]#.split(",") if params[:outcome_val]
      undo = params[:undo]
      outcome_values = []
      previous_values = params[:last_changes].split(",") if params[:last_changes]
      profile_ids.each do |d|
        outcome_values.push(outcome_val)
      end
      previous_grade = ""
      if !profile_ids.nil?
        if undo == "true" and !previous_values.blank?
         previous_grade = OutcomeGrade.outcome_points(school_id,course_id,outcome_id, profile_ids,average,task_id,previous_values)
       else
        previous_grade = OutcomeGrade.outcome_points(school_id,course_id,outcome_id, profile_ids,average,task_id,outcome_values)
      end
      render :json => {:average => average,:previous_grade=>previous_grade}
    end
  end
end

  #load Notes
  def load_notes
    if params[:course_id] && !params[:course_id].blank?
      @profile = Profile.find(user_session[:profile_id])
      @participant = Participant.all( :joins => [:profile => :user],
        :conditions => ["participants.target_id = ? AND participants.profile_type = 'S' AND target_type = 'Course' AND users.status != 'D'", params[:course_id]],
        :select => ["profiles.full_name,participants.id,participants.profile_id"])
      if not @participant.nil?
        @participant.each do |p|
          participant_note = CourseGrade.load_notes(p.profile_id, params[:course_id], @profile.school_id)
          if participant_note.blank?
            p["notes"] = ""
          else
            p["notes"] = participant_note
          end
        end
      end
      @count = @participant.count
      render :json => {:participant => @participant,:count => @count}
    end
  end

  def load_achievements
    course_id = params[:course_id]
    if course_id && !course_id.blank?
      @profile = Profile.find(user_session[:profile_id])
      @participant = Participant.all( :joins => [:profile => :user],
        :conditions => ["participants.target_id = ? AND participants.profile_type = 'S' AND target_type = 'Course' AND users.status != 'D'", course_id],
        :select => ["profiles.full_name,participants.id,participants.profile_id"])
      if not @participant.nil?
        @participant.each do |p|
          (p["xp"], p["total_xp"]) = p.profile.total_xp(course_id)
          p["like_received"] = p.profile.total_like(course_id)
          course_badges = AvatarBadge.where(course_id: course_id, profile_id: p.profile_id)
          p["badge_count"] = course_badges.count
          p["badge_image_urls"] = course_badges.collect{|x| x.badge.image_url}
          p["avatar_badge_ids"] = course_badges.collect{|x| x.id}
        end
      end
      @count = @participant.count
      render :json => {:participant => @participant,:count => @count}
    end
  end
  
  #Save Notes for praticipants
  def save_notes
    if params[:course_id] && !params[:course_id].blank?
      school_id = params[:school_id]
      course_id = params[:course_id]
      notes = params[:notes]
      profile_id = params[:profile_id]
      #participant = Participant.find(participant_id)
      notes = CourseGrade.save_notes(profile_id, course_id,school_id,notes)
      render :json => {:notes => @notes}
    end
  end

  def show_outcomes
    show_outcomes = params[:show] == "true" ? true : false
    @latest_course = Course.find(params[:course_id])
    @latest_course.update_attribute("show_outcomes",show_outcomes)
    render :json => {:success => true}
  end

  def course_outcomes
   if !params[:course_id].blank?
    @course = Course.find(params[:course_id])
    @outcomes_course = @course ? @course.outcomes.order('name') : nil
    @categories = Category.find(:all, :conditions=>["course_id = ?",@course.id])
    render :partial => "/grade_book/add_new_task"
  end
end


def load_outcomes
  if !params[:course_id].blank?
    @course = Course.find(params[:course_id])
    @profile = Profile.find(user_session[:profile_id])
    @outcomes = @course ? @course.outcomes.order('name') : nil
    @participant = Participant.all( :joins => [:profile => :user], :conditions => ["participants.target_id=? AND participants.profile_type = 'S' AND target_type = 'Course' AND users.status != 'D'",@course.id],:select => ["profiles.full_name,participants.id,participants.profile_id"], :order =>"full_name")
    if not @participant.nil?
      @participant.each do |p|
        outcomes_grade = []
        if !@outcomes.nil?
          @outcomes.each do |o|
            outcome_grade = CourseGrade.load_outcomes(p.profile_id, params[:course_id],o.id,@profile.school_id)
            if outcome_grade.nil?
              outcome_grade=""
            end
            outcomes_grade.push(outcome_grade)
          end
          p["course_outcomes"] = outcomes_grade
        end
      end
    end
    @count = @participant.count
    render :json => {:outcomes => @outcomes, :participants=>@participant, :count=>@count}
  end
end

def grading_complete
  if params[:id] and !params[:id].blank?
    if @course = Course.find(params[:id])
      @course.delay.finalize(current_profile)
      render :json => { :running => true }
    else
      render :json =>{:status => status, :text =>"course not found"}
    end
  end
end

def load_task_setup
  if params[:task_id] and !params[:task_id].blank?
    @task = Task.find(params[:task_id])
    @course = @task.course if @task
    @outcomes_course = @course ? @course.outcomes.order('name') : nil
    @categories = Category.find(:all, :conditions=>["course_id = ?",@course.id])
    render :partial=>"/grade_book/load_task_setup"
  end
end

def task_setup
  if params[:task_id] and !params[:task_id].blank?
    @task = Task.find(params[:task_id])
    if @task
      @task.name = params[:task_name] if params[:task_name]
      @task.category_id = params[:category_id] if params[:category_id]
      if @task.save
        unchecked_outcomes = params[:outcomes] ? @task.outcomes.map(&:id) - params[:outcomes].map{|s| s.to_i} : @task.outcomes.map(&:id)
        unchecked_outcomes.each do |outcome_uncheck|
          OutcomeTask.destroy_all(["outcome_id = ? AND task_id = ?", outcome_uncheck, @task.id])
        end

        new_outcomes = params[:outcomes].map{|s| s.to_i} - @task.outcomes.map(&:id) if params[:outcomes]
        if params[:outcomes] && !params[:outcomes].empty?
         new_outcomes.each do |o|
           if o !=""
             outcome_task = OutcomeTask.find(:first, :conditions => ["task_id = ? AND outcome_id = ?", @task.id, o])
             if !outcome_task
                 #OutcomeTask record
                 @outcome_task = OutcomeTask.new
                 @outcome_task.task_id = @task.id
                 @outcome_task.outcome_id = o
                 #@outcome_task.points_percentage = params[:points]
                 @outcome_task.save
               end
             end
           end
         end
         render :json =>{:status=> true}
       end
     end
   end
 end

 def export_course_sectioned_csv
  @course = Course.find(params[:course_id])

  user_csv = CSV.generate do |csv|

    @courses = Course.where(:code => @course.code).order(:section)
    @courses.each do |course|
      @outcomes = course.outcomes.order('name')

      csv << Array.new(@outcomes.count + 1, '')
      csv << ([course.code_section, ''] + @outcomes.map(&:name))

      @profiles = Profile.all(
        :include => [:participants],
        :conditions => {:participants => {:target_id => course.id, :profile_type => 'S'}},
        :order => "full_name"
        )

      @profiles.each do |profile|
        row = ['', profile.full_name]

        @outcomes.each do |outcome|
          @outcome_grade = OutcomeGrade.find(:first, :conditions => {
            :course_id => course.id,
            :outcome_id => outcome.id,
            :profile_id => profile.id
            })

          row.push @outcome_grade && @outcome_grade.grade ? @outcome_grade.grade : '-'
        end

        csv << row
      end
    end
  end

  filename = "#{@course.code}-#{Date.today.strftime('%Y%m%d')}.csv"
  send_data(user_csv, :type => 'text/csv', :filename => filename)
end

def export_course_grade_csv
  x = []
  y = []
  if params[:course_id] && !params[:course_id].blank?
    @course = Course.find(params[:course_id])
    @outcomes = @course.outcomes.order('name')
    @tasks = Course.sort_course_task(@course.id)
    @participant = Participant.all( :joins => [:profile => :user],
      :conditions => ["participants.target_id = ? AND participants.profile_type = 'S' AND target_type = 'Course' AND users.status != 'D'", params[:course_id]],
      :select => ["profiles.full_name,participants.id,participants.profile_id"],
      :order => "full_name"
      )
    y << "Levelfly ID"
    y << "Name"
    y << "Course Code"
    y << "Course Term"
    y << "Course Grade (Numerical)"
    y << "Course Grade (Letter)"
    y << "Notes"
    if @outcomes.length > 0
      if !@outcomes.nil?
        @outcomes.each do|o|
          y << o.name
        end
      end
    end
    if @tasks.length > 0
      if !@tasks.nil?
        @tasks.each do|t|
          y << t.name
          @task_outcomes = t.outcomes.sort_by{|m| m.name.downcase}
          if @task_outcomes.length > 0
            if !@task_outcomes.nil?
              @task_outcomes.each do|o|
                y << "#{o.name} (#{t.name})"
              end
            end
          end
        end
      end
    end
    if !@participant.nil?
      @participant.each do |p|
        x << p.profile.user_id
        x << p.full_name
        x << @course.code_section
        x << @course.semester_year
        participant_grade, outcome_grade = CourseGrade.load_grade(p.profile_id, @course.id,@course.school_id)
        val = participant_grade[@course.id]
        grade = ""
        if !val.nil?
#            grade = val.to_s+" "+GradeType.value_to_letter(val, @course.school_id)
grade = val
x << grade
grade = GradeType.value_to_letter(val, @course.school_id)
x << grade
end
participant_note = CourseGrade.load_notes(p.profile_id, @course.id, @course.school_id)
if participant_note.blank?
  x << ""
else
  x << participant_note
end
if @outcomes.length>0
  if !@outcomes.nil?
    @outcomes.each do |o|
      outcome_grade = CourseGrade.load_outcomes(p.profile_id, @course.id,o.id,@course.school_id)
      x << outcome_grade
    end
  end
end
if @tasks.count > 0
  if !@tasks.nil?
    @tasks.each do|t|
      task_grade = TaskGrade.load_task_grade(t.school_id,t.course_id,t,p.profile_id)
      grade = ""
      if !task_grade.nil?
        grade = GradeType.value_to_letter(task_grade, t.school_id ) unless @course.display_number_grades
        grade = task_grade if @course.display_number_grades
      end
      x << grade
      @task_outcomes = t.outcomes
      if @task_outcomes.length > 0
        if !@task_outcomes.nil?
          @task_outcomes.each do|o|
            outcome_grade = OutcomeGrade.load_task_outcomes(@course.school_id, @course.id,t.id,p.profile_id,o.id)
            x << outcome_grade
          end
        end
      end
    end
  end
end
x << "\m"
end
end
user_csv = CSV.generate do |csv|
  y = y.split("\m")
  y.each do |i|
    csv << i
  end
  x = x.split("\m")
  x.each do |i|
    csv << i
  end
end
filename = @course.code + "-" + @course.section + "-" + Date.today.strftime("%Y%m%d") + ".csv"
send_data(user_csv, :type => 'test/csv', :filename => filename)
end
end

end
