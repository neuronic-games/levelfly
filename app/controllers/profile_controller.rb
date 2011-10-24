class ProfileController < ApplicationController
  
  def index
  end

  def show
    if session[:profile_id].blank?
      @profile = Profile.find_by_code("DEFAULT", :include => [:avatar])
    else
      @profile = Profile.find(session[:profile_id])
    end

    render :text => {"profile"=>@profile, "avatar"=>@profile.avatar}.to_json
  end

  def new
  end

  def edit
    wardrobe_items = WardrobeItem.find(:all, 
      :conditions => ["archived = ?", false],
      :order => "depth, sort_order")
    
    render :text => wardrobe_items.to_json
  end
  
  def save
    id = params[:id]
    profile = params[:profile]
    avatar = params[:avatar]
    if profile["code"] == "DEFAULT"
      # Save a new profile
      @profile = Profile.new
      @avatar = Avatar.new
    else
      @profile = Profile.find(id)
      @avatar = @profile.avatar
    end

    @profile.full_name = profile["full_name"]
    @profile.save

    @avatar.head = avatar["head"]
    @avatar.body = avatar["body"]
    @avatar.top = avatar["top"]
    @avatar.bottom = avatar["bottom"]
    @avatar.hair = avatar["hair"]
    @avatar.shoes = avatar["shoes"]
    @avatar.profile_id = @profile.id
    @avatar.save

    session[:profile_id] = @profile.id
    
    render :text => {"profile"=>@profile, "avatar"=>@avatar}.to_json
  end
end
