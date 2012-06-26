class GradeBookController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
    def index
       @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
       if @profile
         @courses = Course.find(
           :all, 
           :select => "distinct *",
           :include => [:participants], 
           :conditions => ["participants.profile_id = ? AND parent_type = ? AND participants.profile_type = ? AND courses.archived = ?", @profile.id, Course.parent_type_course, Course.profile_type_master, false],
           :order => 'courses.created_at DESC'
         )
         
         if @courses.length > 0
           @school_id = @profile.school_id
           @latest_course = @courses.first    
           @course_id = @latest_course.id
           @outcomes = @latest_course.outcomes
           @participant = Participant.all( :joins => [:profile], :conditions => ["participants.object_id=? AND participants.profile_type = 'P' AND object_type = 'Course'",@course_id],:select => ["profiles.full_name,participants.id,participants.profile_id"])
           #@participant = @courses.first.participants
           @tasks = Task.find(:all,:conditions=>["course_id = ?",@course_id], :select => "name,id")
          
         end
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

    def get_task
      if params[:course_id] && !params[:course_id].nil?
        @profile = Profile.find(user_session[:profile_id])
        @course = Course.find(params[:course_id])
        @outcomes = @course.outcomes
        #@outcomes = @course.outcomes
        @participant = Participant.all( :joins => [:profile], 
          :conditions => ["participants.object_id = ? AND participants.profile_type = 'S' AND object_type = 'Course'", params[:course_id]],
          :select => ["profiles.full_name,participants.id,participants.profile_id"])
        @tasks = Task.find(:all,:conditions=>["course_id = ?",params[:course_id]], :select => "name,id")
        #@participant = @course.participants
          if not @participant.nil?
            @participant.each do |p|
              outcomes_grade = []
              array_task_grade = []
              array_task_outcome_grade = []
              participant_grade, outcome_grade = CourseGrade.load_grade(p.profile_id, params[:course_id])
              if participant_grade.blank?
                p["grade"] = ""
              else   
                participant_grade.each do |key, val|
                  grade = GradeType.value_to_letter(val, @profile.school_id)
                  p["grade"] = grade
                end  
              end
              if !@outcomes.nil?
                @outcomes.each do |o|
                  outcome_grade = CourseGrade.load_outcomes(p.profile_id, params[:course_id],o.id)
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
                  #puts"#{array_task_outcome_grade}===#{}" 
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
            end
          end
      end
      # render :partial => "/grade_book/show_participant"
      respond_to do |format|
        format.html # index.html.erb
        format.json   {
        render :json =>{ 
          :tasks => @tasks,
          :participant => @participant,
          :outcomes => @outcomes,
          :profile => @profile}}
      end

    end
    
  def grade_calculate
    if params[:characters] && !params[:characters].nil?
      characters = params[:characters]
      school_id = params[:school_id]
      course_id = params[:course_id]
      task_id = params[:task_id]
      participant_id = params[:participant_id]
      task_grade = params[:task_grade]
      participant = Participant.find(participant_id)
      num = GradeType.is_num(task_grade)
      previous_grade=""
      if num == false     
        points = GradeType.letter_to_value(task_grade, school_id)
        task_grade = points
      end
      
      # Save the grade
      if !participant.nil?      
        # Calculate the GPA
        sum = 0
        count = 0
        average = 0 
        #percent = -1
        characters.each do |c|
          percent = -1
          if !c.blank?
          num = GradeType.is_num(c)
            if num == true
              percent = c.to_f
            else
              percent = GradeType.letter_to_value(c, school_id)
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
        @grade = GradeType.value_to_letter(average, school_id)
        @grade_task = TaskGrade.task_grades(school_id,course_id,task_id, participant.profile_id,task_grade,average)
        if !@grade_task.blank?
          previous_grade = GradeType.value_to_letter(@grade_task, school_id)
        end
          render :json => {:grade => @grade,:previous_grade=>previous_grade}
      end  
    end
  end
  
  def outcomes_points
    if params[:course_id] && !params[:course_id].nil?
      average = params[:average]
      school_id = params[:school_id]
      course_id = params[:course_id]
      outcome_id = params[:outcome_id]
      participant_id = params[:participant_id]
      task_id = params[:task_id]
      outcome_val = params[:outcome_val]
      participant = Participant.find(participant_id)
      previous_grade = ""
      if !participant.nil?
        previous_grade = OutcomeGrade.outcome_points(school_id,course_id,outcome_id, participant.profile_id,average,task_id,outcome_val)
        render :json => {:average => average,:previous_grade=>previous_grade}
      end  
    end
    
  end
  

end
