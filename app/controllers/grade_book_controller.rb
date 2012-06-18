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
         
           @latest_course = @courses.first    
           @course_id = @latest_course.id
           @outcomes = @latest_course.outcomes
           @participant = Participant.all( :joins => [:profile], :conditions => ["participants.object_id=? AND object_type = 'Course'",@course_id],:select => ["profiles.full_name,participants.id"])
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
         @participant = Participant.all( :joins => [:profile], :conditions => ["participants.object_id=? AND object_type = 'Course'",params[:course_id]],:select => ["profiles.full_name,participants.id"])
         #@participant = @course.participants
         @tasks = Task.find(:all,:conditions=>["course_id = ?",params[:course_id]], :select => "name,id")
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
    
      # Save the grade
      if !participant.nil?
        @grade_task = TaskGrade.task_grades(school_id,course_id,task_id, participant.profile_id,task_grade)
        # Calculate the GPA
        sum = 0
        count = 0
        average = 0 
        characters.each do |c|
          percent = GradeType.letter_to_value(c, school_id)
          if percent.nil?
            percent=0
          end
          sum = sum + percent
          count= count + 1
        end  
        average = sum/count
        @grade = GradeType.value_to_letter(average, school_id)
        render :json => {:grade => @grade}
      end  
    end
  end
  
  def outcomes_points
    if params[:course_id] && !params[:course_id].nil?
      points = params[:points]
      school_id = params[:school_id]
      course_id = params[:course_id]
      outcome_id = params[:outcome_id]
      participant_id = params[:participant_id]
      participant = Participant.find(participant_id)
      if !participant.nil?
        @grade = OutcomeGrade.outcome_points(school_id,course_id,outcome_id, participant.profile_id,points)
        render :json => {:points => points}
      end  
    end
    
  end

end
