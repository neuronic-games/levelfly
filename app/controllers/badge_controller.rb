class BadgeController < ApplicationController

layout 'main'
before_filter :authenticate_user!
 
 def give_badges
    if params[:course_id] && !params[:course_id].nil?
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      course_ids = Course.find(:all, :include => [:participants], :conditions=>["participants.profile_id = ? and participants.profile_type = 'M' and participants.object_type = 'Course' and parent_type = 'C'", user_session[:profile_id]],:order=>"courses.name")
      
      @courses = Course.find(:all, :include => [:participants], :conditions=>["participants.profile_id = ? and participants.object_id in(?) and participants.profile_type = 'S' and participants.object_type = 'Course' and parent_type = 'C'", params[:profile_id], course_ids],:order=>"courses.name")
      @badges ,@last_used= Badge.load_all_badges(@profile)
      #@last_used = Badge.last_used(@profile.school_id,@profile.id)
      render :partial =>"/badge/give_badges",:locals=>{:course_id=>params[:course_id],:profile_id=>params[:profile_id]}
    end
  end
  
  def new_badges
    #@badges = Badge.create
    @badge_image = BadgeImage.all
    render :partial =>"/badge/new_badges", :locals=>{:course_id=>params[:course_id],:profile_id=>params[:profile_id]}
  end
  
  def save
    if params[:badge_image_id] && !params[:badge_image_id].nil?
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      @badge = Badge.new
      @badge.name = params[:badge_name]
      @badge.descr = params[:descr]
      @badge.badge_image_id = params[:badge_image_id]
      @badge.school_id = @profile.school_id
      @badge.creator_profile_id = @profile.id
      course_ids = Course.find(:all, :include => [:participants], :conditions=>["participants.profile_id = ? and participants.profile_type = 'M' and participants.object_type = 'Course' and parent_type = 'C'", user_session[:profile_id]],:order=>"courses.name")
      
      @courses = Course.find(:all, :include => [:participants], :conditions=>["participants.profile_id = ? and participants.object_id in(?) and participants.profile_type = 'S' and participants.object_type = 'Course' and parent_type = 'C'", params[:profile_id], course_ids],:order=>"courses.name")
      if @badge.save
        if params[:submit_type] and !params[:submit_type].nil?
         if params[:submit_type] == "give"
          status = AvatarBadge.add_badge(params[:profile_id],@badge.id,params[:course_id],@profile.id)
          end
        end
        @badges, @last_used = Badge.load_all_badges(@profile)
        render :partial =>"/badge/give_badges",:locals=>{:course_id=>params[:course_id],:profile_id=>params[:profile_id]}
      end
    end
  end
  
  def give_badge_to_student
    if (params[:badge_id] && !params[:badge_id].nil?) #&& (params[:course_id] && !params[:course_id].nil?) &&(params[:profile_id] && !params[:profile_id].nil?)
      status = false
      text = ""
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      #@student = Profile.find(params[:profile_id])
      #@badge = Badge.find(params[:badge_id]) 
      if !@profile.nil?
        status = AvatarBadge.add_badge(params[:profile_id],params[:badge_id],params[:course_id],@profile.id)
      else
        text="Profile not found" 
      end
      render :json => {:status => status, :text=>text}
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
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      @badge = Badge.find(params[:badge_id]) 
      if @badge
        profile_ids = AvatarBadge.find(:all, :select=>"profile_id",:conditions=>["giver_profile_id = ? and badge_id = ?",@profile.id,@badge.id]).collect(&:profile_id)
        #if !@badge_people.nil?
        AvatarBadge.delete_all(["giver_profile_id = ? and badge_id = ?",@profile.id,@badge.id])
        @badge.delete
        if profile_ids and !profile_ids.nil?
          @badge_peoples =Profile.find(:all, :conditions=>["id in(?)",profile_ids])
          @badge_peoples.each do |p|
            p.badge_count-=1
            p.save
          end  
        end
        #end
      end
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
