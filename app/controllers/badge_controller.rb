class BadgeController < ApplicationController

layout 'main'
before_filter :authenticate_user!
 
 def give_badges
    if params[:course_id] && !params[:course_id].nil?
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
     # badge_ids = AvatarBadge.find(:all, :select => "badge_id", :conditions =>["course_id = ?",params[:course_id]]).collect(&:badge_id)
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
      @badge.badge_image_id = params[:badge_image_id]
      @badge.school_id = @profile.school_id
      @badge.creator_profile_id = @profile.id
      if @badge.save
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
      #@profile = Profile.find(params[:profile_id])
      if !@profile.nil?
        status = Badge.check_badge(params[:profile_id],params[:badge_id],params[:course_id])
        if status == true
          @avatar_badge = AvatarBadge.new
          @avatar_badge.profile_id = params[:profile_id]
          @avatar_badge.badge_id  = params[:badge_id]
          @avatar_badge.course_id = params[:course_id]
          @avatar_badge.giver_profile_id = @profile.id
          @avatar_badge.save
        end
      else
        text="Profile not found" 
      end
      render :json => {:status => status, :text=>text}
    end
  end
  
  def warning_box
    if params[:badge_id] && !params[:badge_id].nil?
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      @count_students = AvatarBadge.select("count(*) as total").where("badge_id = ? and giver_profile_id = ?",params[:badge_id],@profile.id)
      render :partial =>"/badge/warning_box"
    end
  end
  
  def delete_badge
    if params[:badge_id] && !params[:badge_id].nil?
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      @badge = Badge.find(params[:badge_id]) 
      if @badge
        @badge_people = AvatarBadge.find(:all, :select=>"id",:conditions=>["giver_profile_id = ? and badge_id = ?",@profile.id,@badge.id]).collect(&:id)
        if !@badge_people.nil?
          puts"#{@badge_people.count}"
          AvatarBadge.delete_all(["id in (?)", @badge_people])
        end
      end
    end
    render :text=> "DELETED"
  end

end
