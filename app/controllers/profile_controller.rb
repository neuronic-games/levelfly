class ProfileController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  protect_from_forgery :except => :auth

  def index
    @profile = Profile.find(user_session[:profile_id])
    if params[:search_text]
      search_text =  "%#{params[:search_text]}%"
      @profiles = Profile.find(
        :all,
        :include => [:user],
        :conditions => [
          "school_id = ? and (lower(full_name) LIKE ? OR lower(users.email) LIKE ?) and user_id is not null and users.status != 'D'",
          @profile.school_id,
          search_text.downcase,
          search_text.downcase
        ],
        :order => "full_name",
        :joins => [:user]
      )
    end
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/profile/people"
        else
          render
        end
      end
    end
  end

  def show
    if params[:id].blank?
      @profile = current_profile
      publish_profile(@profile)
    else
      @profile = Profile.find(params[:id])
    end

    new_profile = nil

    if @profile.nil?
      school_id = school.id
      if user_session[:profile_id].blank?
        new_profile = Profile.find(:first, :conditions => ["code = ? and school_id = ?", "DEFAULT", school_id], :include => [:avatar])
      else
        @profile = Profile.find_by_id(user_session[:profile_id])
        if @profile.nil?
          new_profile = Profile.find(:first, :conditions => ["code = ? and school_id = ?", "DEFAULT", school_id], :include => [:avatar])
        end
      end
    end

    if new_profile
      @profile = Profile.create_for_user(current_user.id,school.id)
      publish_profile(@profile)
    end

    render :text => {"profile"=>@profile, "avatar"=>@profile.avatar, "new_profile"=>new_profile, "major"=>@profile.major, "school"=>@profile.school}.to_json
  end

  def edit
    profile = Profile.find(user_session[:profile_id])
    ids = profile.sports_reward
    wardrobe_items = WardrobeItem.find(:all,
      :conditions => ["archived = ? and wardrobe_id in (?)", false, ids],
      :order => "depth, sort_order")

    render :text => wardrobe_items.to_json
  end

  def save_meta
    id = params[:id]
    profile = params[:profile]
    @profile = Profile.find(id)

    #@profile.full_name = profile["full_name"]
    @profile.major_id = profile["major_id"]
    @profile.school_id = profile["school_id"]
    @profile.interests = profile["interests"]
    @profile.contact_info = profile["contact_info"]
    @profile.save

    publish_profile(@profile)

    render :text => {"profile"=>@profile}.to_json
  end

  def save_notes
    id = params[:id]
    @profile = Profile.find(id)
    Note.delete_all(["profile_id = ? and about_object_id = ? and about_object_type = 'Profile'",user_session[:profile_id],@profile.id])
    if !params[:notes].blank?
      new_note = Note.new
      new_note.profile_id = user_session[:profile_id]
      new_note.about_object_id = @profile.id
      new_note.about_object_type = "Profile"
      new_note.content = params[:notes]
      new_note.save
    end
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

    #@profile.full_name = profile["full_name"]
    @profile.major_id = profile["major_id"]
    @profile.school_id = profile["school_id"]
    @profile.user_id = current_user.id if current_user
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
     file_name = "avatar_#{@profile.id}_#{@profile.updated_at.strftime('%Y%m%d%H%M%S')}.jpg"
     bucket = "#{ENV['S3_PATH']}/schools/#{@profile.school_id}/avatars"
     @profile.image_file_name = "https://s3.amazonaws.com/#{bucket}/#{file_name}"
     @profile.save
     Attachment.aws_upload_base64(@profile.school_id, bucket, file_name, Base64.decode64(params[:avatar_img]))
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
    previous_level = nil
    if params[:profile_id].blank?
      @profile = current_profile
      @badge = Badge.badge_count(@profile.id)
      @courses = Course.course_filter(@profile.id,"") # Courses a student has taken should only be shown to the student and not to others due to FERPA
    else
      @profile = Profile.find(params[:profile_id])
      @badge = Badge.badge_count(@profile.id)
      notes = Note.find(:first, :conditions =>["profile_id = ? and about_object_id = ? and about_object_type = 'Profile'",user_session[:profile_id], @profile.id])
      if !notes.nil?
        @notes = notes.content
      end
    end
    previous_level = @profile.level
    @current_friends = @profile.friends
    @groups = Course.all_group(@profile,"M")
    @major = Major.find(:all, :conditions =>["school_id = ? ",@profile.school_id])
    #@level = Reward.find(:first, :conditions=>["xp <= ? and target_type = 'level'",  @profile.xp], :order=>"xp DESC")
    #puts"#{@level.inspect}"
    #@profile.level = @level.target_id
    #@profile.save
    @levels = Reward.find(:all, :select => "distinct xp", :conditions=>["target_type = 'level'"], :order=>"xp ASC").collect(&:xp)
    if(previous_level != @profile.level)
      content = "Congratulations! You have achieved level #{@profile.level}."
      Message.send_notification(@profile.id,content,@profile.id)
    end
    render :partial => "/profile/user_profile", :locals => {:profile => @profile}
  end

  def edit_wardrobe
    if params[:profile_id].blank?
      @profile = Profile.find(user_session[:profile_id])
    else
      @profile = Profile.find(params[:profile_id])
    end
    @edit = true
    render :partial => "/profile/edit_wardrobe", :locals => {:profile => @profile}
  end

  def account_setup
    if params[:id] && !params[:id].nil?
      @selected_user = Profile.find(params[:id])
      render :partial => "profile/account_setup"
    end
  end

  def change_password
    if params[:id] and not params[:id].nil?
      @user = User.find(params[:id])

      if params[:email] == @user.email
        msg = alert = "You updated your account successfully."
      else
        msg = "An email has been sent to '#{params[:email]}' to confirm that you are the owner of this email address. Please click on the confirmation link in this email address to complete the email change. Check your spam folder if you don't see the email. If you still don't see the email, please contact Levelfly Support."
        alert = "Email verification sent."
      end

      @user.email = params[:email] if params[:email]
      if params[:password] and !params[:password].blank?
        @user.password = params[:password]
      end
      if @user.save
        profile = Profile.find(params[:profile_id])
        profile.full_name = params[:full_name]
        profile.save
        # sign_in(@user, :bypass => true)
        render :json =>{:text => msg, :alert => alert, :status => true, :current_user_profile => user_session[:profile_id]}
      else
        render :json =>{:text =>"ERROR", :alert => "ERROR", :status =>false}
      end
    end
  end

  def show_comments
    if params[:id] and not params[:id].nil?
      @profile = Profile.find(params[:id])
    else
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    end
    @profile.all_comments = params[:show]== "true" ? true : false
    @profile.save
    render :json => {:message => @profile.all_comments, :status => true}
  end

  def update_show_date
    if params[:id] and params[:update]
      @profile = Profile.find(params[:id])
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id]) unless @profile
      @profile.post_date_format = @profile.post_date_format == "D" ? "E" : "D"
      if @profile.save
        render :json =>{:status =>true, :show => @profile.post_date_format}
      else
        render :json =>{:status =>false}
      end
    end
  end

  def change_school
    current_user.default_school = School.find(params[:school_id])
    current_user.save

    render :json => {:status => true}
  end

  def check_email
    render :json => {:exists => params[:email] != current_user.email && User.where(:email => params[:email]).count > 0}
  end

  def change_extended_logout_preference
    profile = Profile.find(current_profile.id)
    profile.extended_logout = params[:extended_logout]
    if profile.save
      render :json => {:success => true} and return
    end
    render :json => {:success => false}
  end

  def auth
    if current_profile
      response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
      render :json => response
    else
      render :text => "Forbidden", :status => '403'
    end
  end

  def save_privacy_settings
    @profile = current_user.profiles.first
    @profile.is_public = params[:is_public]
    @profile.friend_privilege = params[:friend_privilege]
    # @profile.friend_privilege = (!@profile.is_public && params[:friend_privilege] == '1') ? true : (@profile.is_public && params[:friend_privilege].present?) ? false : nil
    @profile.save!
    puts @profile.inspect
    render :json => {:success => true}
  end

end
