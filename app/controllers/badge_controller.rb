class BadgeController < ApplicationController

layout 'main'
before_filter :authenticate_user!
 
 def give_badges
    if params[:course_id] && !params[:course_id].nil?
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
     # badge_ids = AvatarBadge.find(:all, :select => "badge_id", :conditions =>["course_id = ?",params[:course_id]]).collect(&:badge_id)
      @badges = Badge.where("school_id = ?",@profile.school_id)
      render :partial =>"/badge/give_badges"
    end
  end
  
  def new_badges
    #@badges = Badge.create
    render :partial =>"/badge/new_badges"
  end
  
  def save
    if params[:image] && !params[:image].nil?
      @badge_image = BadgeImage.new
      @badge_image.image = File.open(params[:image])
      if @badge_image.save
        render :text=>"Image Save"
      end
    end
  end

end
