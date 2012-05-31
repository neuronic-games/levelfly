class GradeBookController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
    def index
       @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
       if @profile
       @courses = Course.find(
          :all, 
          :include => [:participants]
          #:conditions => ["participants.profile_id = ? AND participants.profile_type != 'P'", @profile.id],
          #:order => 'name'
       )
       @tasks = Task.find(:all)

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
         @tasks = Task.find(:all,:conditions=>["course_id = ?",params[:course_id]], :select => "name,id")
       end
       render :partial => "/grade_book/show_task"
    end

end
