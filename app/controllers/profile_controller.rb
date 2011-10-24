class ProfileController < ApplicationController
  
  def index
  end

  def show
    if session[:profile_id].blank?
      @profile = Profile.find_by_code("DEFAULT", :include => [:avatar])
    else
      @profile = Profile.find_by_id(session[:profile_id])
      if @profile.nil?
        @profile = Profile.find_by_code("DEFAULT", :include => [:avatar])
      end
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

    @avatar.skin = avatar["skin"]
    @avatar.background = avatar["background"]
    @avatar.body = avatar["body"]
    @avatar.hat_back = avatar["hat_back"]
    @avatar.hair_back = avatar["hair_back"]
    @avatar.shoes = avatar["shoes"]
    @avatar.bottom = avatar["bottom"]
    @avatar.necklace = avatar["necklace"]
    @avatar.top = avatar["top"]
    @avatar.head = avatar["head"]
    @avatar.earrings = avatar["earrings"]
    @avatar.facial_marks = avatar["facial_marks"]
    @avatar.facial_hair = avatar["facial_hair"]
    @avatar.makeup = avatar["makeup"]
    @avatar.glasses = avatar["glasses"]
    @avatar.hair = avatar["hair"]
    @avatar.hat = avatar["hat"]
    @avatar.prop = avatar["prop"]
    @avatar.profile_id = @profile.id
    @avatar.save

    session[:profile_id] = @profile.id
    
    render :text => {"profile"=>@profile, "avatar"=>@avatar}.to_json
  end
  
  def reset
    session[:profile_id] = nil
    render :text => {"status"=>"ok"}.to_json
  end
  
end
