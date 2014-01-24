class BadgeController < ApplicationController

layout 'main'
before_filter :authenticate_user!
 
 def give_badges
    if params[:course_id] && !params[:course_id].nil?
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      course_ids = Course.find(:all, :include => [:participants], :conditions=>["participants.profile_id = ? and participants.profile_type = 'M' and participants.target_type = 'Course' and parent_type = 'C' and removed = ?", user_session[:profile_id],false],:order=>"courses.name").map(&:id)
      @courses = Course.find(:all, :include => [:participants], :conditions=>["participants.profile_id = ? and participants.target_id in(?) and participants.profile_type = 'S' and participants.target_type = 'Course' and parent_type = 'C'", params[:profile_id], course_ids],:order=>"courses.id")
      @selected_course = Course.find_by_id(params[:last_course]) if params[:last_course]
      @badges ,@last_used= Badge.load_all_badges(@profile)
      #@last_used = Badge.last_used(@profile.school_id,@profile.id)
      render :partial =>"/badge/give_badges",:locals=>{:course_id=>params[:course_id],:profile_id=>params[:profile_id]}
    end
  end
  
  def new_badges
    #@badges = Badge.create
    @badge_image = BadgeImage.find(:all, :conditions => ["image_file_name not in (?)","gold_badge.png"])
    course_ids = Course.find(:all, :include => [:participants], :conditions=>["participants.profile_id = ? and participants.profile_type = 'M' and participants.target_type = 'Course' and parent_type = 'C' and removed = ?", user_session[:profile_id],false],:order=>"courses.name").map(&:id)
    @courses = Course.find(:all, :include => [:participants], :conditions=>["participants.profile_id = ? and participants.target_id in(?) and participants.profile_type = 'S' and participants.target_type = 'Course' and parent_type = 'C'", params[:profile_id], course_ids],:order=>"courses.id")
    @selected_course = Course.find_by_id(params[:last_course])
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    render :partial =>"/badge/new_badges", :locals=>{:course_id=>params[:course_id],:profile_id=>params[:profile_id],:last_course =>params[:last_course]}
  end
  
  def save
    if params[:badge_image_id] && !params[:badge_image_id].nil?
      status = false
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      @badge = Badge.new
      @badge.name = params[:badge_name]
      @badge.descr = params[:descr]
      @badge.badge_image_id = params[:badge_image_id]
      @badge.school_id = @profile.school_id
      @badge.creator_profile_id = @profile.id
      if @badge.save
        if params[:submit_type] and !params[:submit_type].nil?
         if params[:submit_type] == "give"
          status = AvatarBadge.add_badge(params[:profile_id],@badge.id,params[:course_id],@profile.id)
          student = Profile.find_by_id(params[:profile_id])
          student_name = student.full_name if student
          badge_name = @badge.name
          course = Course.find_by_id(params[:course_id])
          course_name = course.name if course
          end
        end
        @badges, @last_used = Badge.load_all_badges(@profile)
        #controller = session[:controller]
        #ProfileAction.last_viewed(@profile, controller, "/#{controller}/show")
        #render :partial =>"/badge/give_badges",:locals=>{:course_id=>params[:course_id],:profile_id=>params[:profile_id]}
       render :json => {:status => true, :student_name=>student_name, :badge_name=>badge_name, :course_name=>course_name, :save_and_give => status, :course_id=>params[:course_id], :last_course_id=>params[:last_course], :profile_id => params[:profile_id]}
      end
    end
  end
  
  def give_badge_to_student
    if (params[:badge_id] && !params[:badge_id].nil?) #&& (params[:course_id] && !params[:course_id].nil?) 
      status = false
      text = ""
      student = Profile.find_by_id(params[:profile_id])
      student_name = student.full_name if student
      badge = Badge.find_by_id(params[:badge_id])
      badge_name = badge.name if badge
      course = Course.find_by_id(params[:course_id])
      course_name = course.name if course
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      if !@profile.nil?
        status = AvatarBadge.add_badge(params[:profile_id],params[:badge_id],params[:course_id],@profile.id)
      else
        text="Profile not found" 
      end
      render :json => {:status => status, :text=>text, :student_name=>student_name, :badge_name=>badge_name, :course_name=>course_name}
    end
  end
  
  def warning_box
    if params[:badge_id] && !params[:badge_id].nil?
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      @count_students = AvatarBadge.where("badge_id = ? and giver_profile_id = ?",params[:badge_id],@profile.id).count
      render :partial =>"/badge/warning_box"
    end
  end
  
  def delete_badge
    if params[:badge_id] && !params[:badge_id].nil?
      @profile = Profile.find(params[:profile_id])
      @badge = Badge.find(params[:badge_id])
      if @badge
        AvatarBadge.delete_all(["profile_id = ? and badge_id = ?",@profile.id,@badge.id])
        @profile.badge_count -= 1 if @profile.badge_count > 0
      end
      @profile.save
    end
    render :text=> "DELETED"
  end

  def badge_detail
    if params[:id] and !params[:id].nil?
      @avatar_badge = AvatarBadge.find(params[:id])
      if @avatar_badge
        @badge_detail = Badge.find(@avatar_badge.badge_id)
        if @badge_detail
          render :partial => "badge/badge_detail"
        else
          render
        end
      end
      
    end   
  end
end
