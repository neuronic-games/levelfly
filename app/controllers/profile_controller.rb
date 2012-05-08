class ProfileController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
  def index
  end

  def show
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    if @profile
      user_session[:profile_id] = @profile.id
    end
    
    new_profile = nil
    
    if @profile.nil?
      if user_session[:profile_id].blank?
        new_profile = Profile.find_by_code("DEFAULT", :include => [:avatar])
      else
        @profile = Profile.find_by_id(user_session[:profile_id])
        if @profile.nil?
          new_profile = Profile.find_by_code("DEFAULT", :include => [:avatar])
          new_profile = true
        end
      end
    end
    
    if new_profile
      @profile = new_profile.dup
      @profile.user_id = current_user.id
      @profile.code = nil
      @profile.save
      avatar = new_profile.avatar.dup
      avatar.profile_id = @profile.id
      avatar.save
      user_session[:profile_id] = @profile.id
    end
    
    render :text => {"profile"=>@profile, "avatar"=>@profile.avatar, "new_profile"=>new_profile, "major"=>@profile.major, "school"=>@profile.school}.to_json
  end

  def edit
    wardrobe_items = WardrobeItem.find(:all, 
      :conditions => ["archived = ?", false],
      :order => "depth, sort_order")
    
    render :text => wardrobe_items.to_json
  end
  
  def save_meta
    id = params[:id]
    profile = params[:profile]
    @profile = Profile.find(id)

    @profile.full_name = profile["full_name"]
    @profile.major_id = profile["major_id"]
    @profile.school_id = profile["school_id"]
    @profile.save
    
    publish_profile(@profile)
    
    render :text => {"profile"=>@profile}.to_json
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
    @profile.major_id = profile["major_id"]
    @profile.school_id = profile["school_id"]
    @profile.user_id = current_user.id if current_user
    if params[:avatar_img]
      #@profile.image.destroy if @profile.image
      #@profile.image = Base64.decode64(params[:avatar_img])
    end
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
    @avatar.face = avatar["face"]
    @avatar.glasses = avatar["glasses"]
    @avatar.hair = avatar["hair"]
    @avatar.hat = avatar["hat"]
    @avatar.prop = avatar["prop"]
    @avatar.profile_id = @profile.id
    @avatar.save
    
    if @avatar.save
     file_name = "avatar_#{user_session[:profile_id]}.jpg"
     Attachment.aws_upload(@profile.school_id, file_name, Base64.decode64(params[:avatar_img]),true)
    end

    publish_profile(@profile)
    
    render :text => {"profile"=>@profile, "avatar"=>@avatar}.to_json
  end
  
  def accept_code
    render :partial => "/profile/code_dialog"
  end

  def change_name
    render :partial => "/profile/name_dialog"
  end
  
  def change_major
    @majors = Major.find(:all, 
      :conditions => ["archived = ?", false],
      :order => "name")
    render :partial => "/profile/major_dialog"
  end
  
  def validate_code
    code = params[:code].to_s.upcase
    access_code = AccessCode.find_by_code(code)
    major = nil
    school = nil
    if access_code
      major = access_code.major
      school = access_code.school
    end
    render :text => {"major"=>major, "school"=>school}.to_json
  end
  
  def user_profile
     if params[:profile_id] && !params[:profile_id].nil?
      @profile = Profile.find(params[:profile_id])
	 end
      render :partial => "/profile/user_profile", :locals => {:profile => @profile}
  end
  
  private
  
  def publish_profile(profile)
    user_session[:profile_id] = @profile.id
    user_session[:profile_name] = @profile.full_name
  end

end
