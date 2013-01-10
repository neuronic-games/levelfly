require 'csv'

class GradeBookController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
  def index
    @enable_palette = false
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    if @profile
      setting = Setting.find(:first, :conditions=>["object_id = ? and value = 'true' and object_type ='school' and name ='enable_grade_palette' ",@profile.school_id])
      if setting and !setting.nil?
        @enable_palette = true
      end
      filter_course("active")
     end
     respond_to do |wants|
      wants.html do
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
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      @courses = [];
      @people =[];
      @tasks = [];
      @course = Course.find(
        :all, 
        :select => "distinct *",
        :include => [:participants], 
        :conditions => ["removed = ? and participants.profile_id = ? AND parent_type = ? AND participants.profile_type = ? AND courses.archived = ?",false, @profile.id, Course.parent_type_course, Course.profile_type_master, archived],
        :order => 'courses.created_at DESC'
      )
      @course.each do |c|
        if c.participants.find(:all, :conditions=>["profile_type in ('M','S')"]).count>1
          @courses.push(c)
        end
      end
      
      if @courses.length > 0
        @school_id = @profile.school_id
        @latest_course = @courses.first    
        @course_id = @latest_course.id
        session[:course_id] = @course_id
        @outcomes = @latest_course.outcomes
        @participant = Participant.all( :joins => [:profile], :conditions => ["participants.object_id=? AND participants.profile_type = 'S' AND object_type = 'Course'",@course_id],:select => ["profiles.full_name,participants.id,participants.profile_id"])
        #@participant = @courses.first.participants
        @count = @participant.count
        @tasks = Course.sort_course_task(@course_id)
      end
  end
  
  def filter
    if params[:filter] && !params[:filter].blank?
      filter_course(params[:filter])
      render :partial => "/grade_book/load_data"
    end
  end
     
  def get_task
    if params[:course_id] && !params[:course_id].blank?
      session[:course_id] = params[:course_id]
      @profile = Profile.find(user_session[:profile_id])
      @course = Course.find(params[:course_id])
      @outcomes = @course.outcomes
      @participant = Participant.all( :joins => [:profile], 
        :conditions => ["participants.object_id = ? AND participants.profile_type = 'S' AND object_type = 'Course'", params[:course_id]],
        :select => ["profiles.full_name,participants.id,participants.profile_id"])
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
                grade = val.to_s + " " + GradeType.value_to_letter(val, @profile.school_id)
                p["grade"] = grade
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
                  grade = GradeType.value_to_letter(task_grade, @profile.school_id)
                end
                array_task_grade.push(grade)
                task_outcomes = t.outcomes
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
            t["task_outcomes"] = t.outcomes
             task = Task.find(t.id)
              if task.category_id != 0 and !task.category_id.nil?
               t["task_category"] = "(#{task.category.name})"
              else
               t["task_category"] = "" 
              end
             
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
        :profile => @profile,
        :count => @count}}
    end

  end
  
   #used for caclulation for grade
  def grade_calculate
    if params[:characters] && !params[:characters].blank?
      characters = params[:characters].split(",") if params[:characters]
      school_id = params[:school_id]
      course_id = params[:course_id]
      task_id = params[:task_id]
      profile_id = params[:profile_id].split(",") if params[:profile_id]
      task_grade = params[:task_grade]
      p=profile_id.length
      arr_grade = []
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
        end
      end
    
      # Save the grade
      if !profile_id.nil?      
        # Calculate the GPA
        sub_arrays = characters.in_groups(p, false)
        profile_id.each_with_index do |p,j|
          sum = 0
          count = 0
          average = 0 
          sub_arrays[j].each_with_index do |grades,i|         
            #grades[1].each do |c|
              percent = -1            
              if !grades.blank?
                num = GradeType.is_num(grades)
                if num == true
                  percent = grades.to_f
                else
                  percent = GradeType.letter_to_value(grades, school_id)
                end    
                if (!percent.nil? and percent > -1)
                  sum = sum + percent
                  count = count + 1
                end
              end 
            end 
          if (sum >0 and count >0)
            average = sum/count
          else
            average = 0 
          end
          @grade = average.round(2).to_s + " " + GradeType.value_to_letter(average, school_id)
          arr_grade.push(@grade)
          if undo == "true" and !previous_values.blank?
            @grade_task = TaskGrade.task_grades(school_id,course_id,task_id, profile_id[j],arr_task_grade[j],average)
            if !@grade_task.blank?
              previous_grade = GradeType.value_to_letter(@grade_task, school_id)
            end
          else
            @grade_task = TaskGrade.task_grades(school_id,course_id,task_id, profile_id[j],task_grade,average)
            if !@grade_task.blank?
              previous_grade = GradeType.value_to_letter(@grade_task, school_id)
            end
          end
        end  
      end  
        render :json => {:grade => arr_grade,:previous_grade=>previous_grade}
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
      @participant = Participant.all( :joins => [:profile], 
      :conditions => ["participants.object_id = ? AND participants.profile_type = 'S' AND object_type = 'Course'", params[:course_id]],
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
  
  def course_outcomes
     if !params[:course_id].blank?
      @course = Course.find(params[:course_id])
      @outcomes_course = @course ? @course.outcomes : nil
      @categories = Category.find(:all, :conditions=>["course_id = ?",@course.id])
      render :partial => "/grade_book/add_new_task"
    end
  end
  
  
  def load_outcomes
    if !params[:course_id].blank?
      @course = Course.find(params[:course_id])
      @profile = Profile.find(user_session[:profile_id])
      @outcomes = @course ? @course.outcomes : nil
      @participant = Participant.all( :joins => [:profile], :conditions => ["participants.object_id=? AND participants.profile_type = 'S' AND object_type = 'Course'",@course.id],:select => ["profiles.full_name,participants.id,participants.profile_id"])
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
      status = false
      url =nil
      @course = Course.find(params[:id])
      if @course
        @course.grading_completed_at = Time.now
        @course.save
        @profile = Profile.find(user_session[:profile_id])
        @badge = Badge.find_by_name("Gold Outcome")
        @outcomes = @course.outcomes
        @participant = Participant.all( :joins => [:profile], :conditions => ["participants.object_id=? AND participants.profile_type = 'S' AND object_type = 'Course'",@course.id],:select => ["profiles.full_name,participants.id,participants.profile_id"])
        @participant.each do |p|
          outcomes_grade = []
          profile_ids = AvatarBadge.find(:all, :select=>"profile_id",:conditions=>["profile_id = ? and badge_id = ? and course_id = ?",p.profile_id,@badge.id,params[:id]]).collect(&:profile_id)
          AvatarBadge.delete_all(["profile_id = ? and badge_id = ? and course_id = ?",p.profile_id,@badge.id,params[:id]])
          if profile_ids and !profile_ids.nil?
            profile_ids.each do
              p.profile.badge_count-=1
              p.profile.save
            end
          end
          if !@outcomes.nil?
            @outcomes.each do |o|
              outcome_grade = CourseGrade.load_outcomes(p.profile_id, params[:id],o.id,@profile.school_id)
              if !outcome_grade.blank?
                outcomes_grade.push(outcome_grade)                  
              end
            end
            outcomes_grade.each do |og|
              if og >= 2.5
                status = AvatarBadge.add_badge(p.profile_id,@badge.id,params[:id],@profile.id)
                url = ProfileAction.last_action(p.profile_id)
              end
            end
          end
        end 
        render :json =>{:status => status, :text =>"Grading complete", :url=>url}
      else
        render :json =>{:status => status, :text =>"course not found", :url=>url}
      end
    end
    
  end
  
  def load_task_setup
    if params[:task_id] and !params[:task_id].blank?
      @task = Task.find(params[:task_id])
      render :partial=>"/grade_book/load_task_setup"
    end
  end
  
  def task_setup
    if params[:task_id] and !params[:task_id].blank?
      @task = Task.find(params[:task_id])
      if @task
        if params[:grading_complete_date] == "true"
          @task.grading_complete_date = Time.now
        else
          @task.grading_complete_date = nil
        end
        @task.show_outcomes = params[:show_outcomes] if params[:show_outcomes]
        @task.include_task_grade =  params[:include_task_grade] if params[:include_task_grade]
        @task.name = params[:task_name] if params[:task_name]
        if @task.save
         render :json =>{:status=> true}
        end
      end  
    end
  end
  
  def export_csv
    x = []
    y = []
    if session[:course_id] && !session[:course_id].blank?
      @course = Course.find(session[:course_id])
      @outcomes = @course.outcomes
      @tasks = Course.sort_course_task(@course.id)
      @participant = Participant.all( :joins => [:profile], 
        :conditions => ["participants.object_id = ? AND participants.profile_type = 'S' AND object_type = 'Course'", session[:course_id]],
        :select => ["profiles.full_name,participants.id,participants.profile_id"])
      y << "User ID"
      y << "Name"
      y << "Course Code"
      y << "Course Grade"
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
            @task_outcomes = t.outcomes
            if @task_outcomes.length > 0
              if !@task_outcomes.nil?
                @task_outcomes.each do|o|
                  y << t.name+": "+o.name
                end
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
        x << @course.code+" - "+@course.section
        participant_grade, outcome_grade = CourseGrade.load_grade(p.profile_id, @course.id,@course.school_id)
        val = participant_grade[@course.id]
        grade = ""
        if !val.nil?
          grade = val.to_s+" "+GradeType.value_to_letter(val, @course.school_id)
        end
        x << grade
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
                grade = GradeType.value_to_letter(task_grade, t.school_id )
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
