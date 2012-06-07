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
           :conditions => ["participants.profile_id = ? AND parent_type = ? AND join_type = ? AND participants.profile_type != ? AND courses.archived = ?", @profile.id, Course.parent_type_course, Course.join_type_invite, Course.profile_type_pending, false],
           :order => 'name'
         )
       
         @participant = Profile.all( :joins => [:participants],:select => ["profiles.full_name"])

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
         @profile = Profile.find(user_session[:profile_id])
         @course = Course.find(params[:course_id])
         @outcomes = @course.outcomes
         @participant = Participant.all( :joins => [:profile], :conditions => ["participants.object_id=? AND object_type = 'Course'",params[:course_id]],:select => ["profiles.full_name"])

         @tasks = Task.find(:all,:conditions=>["course_id = ?",params[:course_id]], :select => "name,id")
       end
       render :partial => "/grade_book/show_participant"
    end

end
