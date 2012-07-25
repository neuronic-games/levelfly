class CourseController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
        require 'digest/sha1'
  def index
    section_type = params[:section_type]
    
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    
    if params[:search_text]
      search_text =  "#{params[:search_text]}%"
      if params[:section_type]=="C"
        @courses = Course.find(
          :all,
          :include => [:participants], 
          :conditions => ["(upper(courses.name) LIKE ? OR upper(courses.code) LIKE ?) and parent_type = ?",search_text.upcase,  search_text.upcase, Course.parent_type_course])
      
      elsif params[:section_type]=="G"
        @courses = Course.find(:all, :conditions=>["(upper(courses.name) LIKE ? OR upper(courses.code) LIKE ?) and parent_type = ? and school_id = ?",search_text.upcase,search_text.upcase, Course.parent_type_group,@profile.school_id])
      end
     
    else

      # Check if the user was working on a details page before, and redirect if so
      return if redirect_to_last_action(@profile, 'course', '/course/show')
      
      if !params[:section_type].nil?
        if params[:section_type] == 'C'
          @courses = Course.course_filter(@profile.id,"")
        end
        if params[:section_type] == 'G'
          @courses = Course.all_group(@profile,"M")
        end
      else
        @courses = []
      end
    end
    
    respond_to do |wants|  
      wants.html do
        if request.xhr?
          render :partial => "/course/list",:locals=>{:section_type=>section_type}
        else
          render
        end
      end
    end
  end
  
  def send_group_invitation
    status = false
    if params[:id] && !params[:id].nil?
      @course = Course.find_by_id(params[:id])
      @participant =  participant = Participant.find(:first, :conditions => ["object_id = ? AND object_type = 'Course' AND profile_id = ? ", params[:id], user_session[:profile_id]])
      if !@participant 
        @participant = Participant.new
        @participant.object_id    = params[:id] if params[:id]
        @participant.profile_id   = user_session[:profile_id]
        @participant.object_type  = "Course"
        @participant.profile_type = "S"  
        if @participant.save
          status = true
        end
      end
      render :text => {"status"=>status}.to_json
    end
  end
  
  def group_joinning
    status = false
    if params[:id] && !params[:id].nil?
      @course = Course.find_by_id(params[:id])
      if @course
        @course.join_type = params[:join_type]
        @course.save
        status = true
      end
      render :text => {"status"=>status}.to_json
    end
  end
  
  def group_viewing
    status = false
    if params[:id] && !params[:id].nil?
      @course = Course.find_by_id(params[:id])
      if @course
        @course.visibility_type = params[:visibility_type]
        @course.save
        status = true
      end
      render :text => {"status"=>status}.to_json
    end
  end
  
  def new
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    # TODO: There is a bug in the view that occurs if a blank course is not saved first.
    # We need to make sure that the id is sent back to the view and the view updated with the id.
    @course = Course.create
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/course/form" ,:locals=>{:course_new=>true,:section_type=>params[:section_type]}
        else
          render
        end
      end
    end
  end
  
  def show
    @course = Course.find_by_id(params[:id])
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    @wall = Wall.find(:first,:conditions=>["parent_id = ? AND parent_type='Course'", @course.id])
    if !@profile.nil?
    @badges = AvatarBadge.select("count(*) as total").where("profile_id = ? and course_id = ?",@profile.id,@course.id)
    end
    xp = TaskGrade.select("sum(points) as total").where("school_id = ? and course_id = ? and profile_id = ?",@profile.school_id,@course.id,@profile.id)
    @course_xp = xp.first.total
    @member_count = Profile.count(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.object_id = ? AND participants.object_type='Course' AND participants.profile_type IN ('M', 'S')", @course.id]
    )
    @pending_count = Profile.count(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.object_id = ? AND participants.object_type='Course' AND participants.profile_type IN ('P')", @course.id]
    )
    @courseMaster = Profile.find(
      :first, 
      :include => [:participants], 
      :conditions => ["participants.object_id = ? AND participants.object_type='Course' AND participants.profile_type = 'M'", @course.id]
      )
    @course_owner = Participant.find(:first, :conditions=>["object_id = ? AND profile_type = 'M' AND object_type='Course'",params[:id]])   
    @totaltask = Task.find(:all, :conditions =>["course_id = ?",@course.id])
    @groups = Group.find(:all, :conditions=>["course_id = ?",@course.id])
    if params[:section_type]=="C"
    @course_messages = Message.find(:all,:conditions=>["parent_id = ? AND parent_type = 'C'",@course.id],:order => "created_at DESC" )
    elsif params[:section_type]=="G"
    @course_messages = Message.find(:all,:conditions=>["profile_id = ? AND parent_id = ? AND parent_type = 'G'",user_session[:profile_id],@course.id],:order => "created_at DESC" )
    end
    @profile.record_action('course', @course.id)
    @profile.record_action('last', 'course')
    session[:controller]="course"
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/course/form",:locals=>{:course_new =>false,:section_type =>params[:section_type]}
        else
           
        end
      end
    end
  end
  
  def save
    if params[:id] && !params[:id].empty?
      @course = Course.find(params[:id])
    else
      # Save a new course
      @course = Course.new
    end
   
    @course.name = params[:course] if params[:course]
    @course.descr = params[:descr] if params[:descr]
    @course.parent_type = params[:section_type] if params[:section_type]
    @course.code = params[:code].upcase if params[:code]
    @course.section = params[:section] if params[:section]
    @course.school_id = params[:school_id] if params[:school_id]
    @course.rating_low = params[:rating_low] if params[:rating_low]
    @course.rating_medium = params[:rating_medium] if params[:rating_medium]
    @course.rating_high = params[:rating_high] if params[:rating_high]
    @course.tasks_low = params[:task_low] if params[:task_low]
    @course.tasks_medium = params[:task_medium] if params[:task_medium]
    @course.tasks_high = params[:task_high] if params[:task_high]
           
    if params[:file]
      @course.image.destroy if @course.image
      @course.image = params[:file]
    end
    
    if @course.save
      #get wall id
      wall_id = Wall.get_wall_id(@course.id,"Course")
      #Save categories
      if params[:categories] && !params[:categories].empty?
        categories_array = params[:categories].split(",")
        loaded_categories_array = params[:percent_value].split(",")
        categories_array.each_with_index do |category,i|
          @category = Category.create(
            :name=> category,
            :percent_value=> loaded_categories_array[i],
            :course_id=> @course.id,
            :school_id=> @course.school_id
          )
        end
      end
      
      # @same_code_courses = Course.find(:all, :conditions=>["code = ? AND id != ?",@course.code, @course.id])
      # if @same_code_courses
      #   @same_code_courses.each do |same_course|
      #     same_course.outcomes.each do |same_outcome|
      #       @course.outcomes << same_outcome
      #     end
      #   end
      # end

      #Save outcomes
      if params[:outcomes] && !params[:outcomes].empty?
        outcomes_array = params[:outcomes].split(",")
        outcomes_descs_array = params[:outcomes_descr].split(",")
        outcomes_share_array = params[:outcome_share].split(",")
        outcomes_array.each_with_index do |outcome,i|
          @outcome = Outcome.create(
            :name=> outcome,
            :descr=> outcomes_descs_array[i],
            :school_id=> @course.school_id,
            :shared=> outcomes_share_array[i]
          )
          @course.outcomes << @outcome
        end
      end
      
      # Participant record for master
      participant = Participant.find(:first, :conditions => ["object_id = ? AND object_type='Course' AND profile_id = ?", @course.id, user_session[:profile_id]])
      if !participant
        @participant = Participant.new
        @participant.object_id = @course.id
        @participant.object_type = "Course"
        @participant.profile_id = user_session[:profile_id]
        @participant.profile_type = "M"
        if @participant.save
          Feed.create(
            :profile_id => user_session[:profile_id],
            :wall_id =>wall_id
          )
        end
      end
      image_url = params[:file] ? @course.image.url : ""
    end
    render :text => {"course"=>@course, "image_url"=>image_url,"outcome"=>@outcome}.to_json
  end
  
   def get_participants
    search_participants()
   end
   
  def add_participant
    status = false
    already_added = false
    new_user = false
    if params[:email] && params[:email]
      if params[:section_type] == 'G'
           section_type = 'Group'
      end   
      if params[:section_type] == 'C'
         section_type = 'Course'
      end 
      @user = User.find_by_email(params[:email])
      if @user 
        @profile = Profile.find_by_user_id(@user.id)
      else
        @user, @profile = User.new_user(params[:email])
        new_user = true
      end
      if @profile
        participant_exist = Participant.find(:first, :conditions => ["object_id = ? AND object_type= ? AND profile_id = ?", params[:course_id], section_type, @profile.id])
        if !participant_exist
          @participant = Participant.new
          @participant.object_id = params[:course_id]
          @participant.object_type = section_type
          @participant.profile_id = @profile.id
          @participant.profile_type = "P"
          if @participant.save
            wall_id = Wall.get_wall_id(params[:course_id],"Course")
            Feed.create(
              :profile_id => @profile.id,
              :wall_id =>wall_id
            )
            # Send a message. It may also send an email.
            @message = Message.send_course_request(user_session[:profile_id], @profile.id, wall_id, params[:course_id],section_type)
            status = true           
          end
        else 
            already_added = true
        end
      end
      if new_user==true
         send_email(params[:email],params[:course_id],@message.id)
        
      end
      render :text => {"status"=>status, "already_added" => already_added,"profile" =>@profile,"user"=>@user,"new_user"=>new_user}.to_json
   end
  end
  
  def send_email(email,course,message_id)
     @course = Course.find(course)
     @current_user = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
     @school = School.find(@current_user.school_id)
     UserMailer.registration_confirmation(email,@current_user,@course,@school,message_id).deliver
  end
  
  def delete_participant
    status = false
    if params[:profile_id] && params[:course_id]
      participant = Participant.find(:first, :conditions => ["object_id = ? AND object_type = 'Course' AND profile_id = ? ", params[:course_id], params[:profile_id]]) 
      if participant
        participant.delete
        @wall_id = Wall.find(:first, :conditions=>["parent_id = ? and parent_type = 'C'",params[:course_id]])
        if !@wall_id.nil?
          @feed = Feed.find(:first, :conditions=>["profile_id = ? and wall_id = ? ",params[:profile_id],@wall_id.id])
          if !@feed.nil?
            @feed.delete
          end
        end
        status = true
      end
    end
    render :text => {"status"=>status}.to_json
  end
  
  def remove_course_outcomes
    if params[:outcomes] && !params[:outcomes].nil?
      Outcome.destroy(params[:outcomes])
      render :text => {"status"=>"true"}.to_json
    end
  end
  
  def remove_course_files
    if params[:files] && !params[:files].nil?
      Attachment.destroy(params[:files])
      render :text => {"status"=>"true"}.to_json
    end
  end
  
  def update_course_outcomes
    if params[:outcome_id] && !params[:outcome_id].empty?
      outcome = Outcome.find(params[:outcome_id])
      outcome.name = params[:outcome] if params[:outcome] && !params[:outcome].empty?
      outcome.save
    end
    render :nothing =>true
  end
  
  def update_course_categories
    if params[:category_id] && !params[:category_id].empty?
      category = Category.find(params[:category_id])
      category.name = params[:category] if params[:category] && !params[:category].empty?
      category.save
    end
    render :nothing =>true
  end
  
  def remove_course_categories
    if params[:categories] && !params[:categories].nil?
      category_array = params[:categories].split(',')
      Category.destroy(category_array)
      render :text => {"status"=>"true"}.to_json
    end
  end
  
  def check_outcomes
    @outcomes = []
    @course = nil
    if params[:code] && !params[:code].nil?
      @courses = Course.find(:all, :conditions =>["code = ?", params[:code]], :order => "created_at")
      if @courses.length > 0
          @courses.each do |course|
            @course = course if @course.nil?
            course.outcomes.where(["shared = ?", true]).each do |value|
              @outcomes << value
            end 
          end
          render :partial => "/course/show_outcomes",:locals=>{:outcomes=>@outcomes}
      else
        render :text=>"No outcomes.."         
      end
    end
  end
  
  def view_group_setup
    
     @course = Course.find_by_id(params[:id])
     @member_count = Profile.count(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.object_id = ? AND participants.object_type='Course' AND participants.profile_type IN ('M', 'S')", @course.id]
      )
      @pending_count = Profile.count(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.object_id = ? AND participants.object_type='Course' AND participants.profile_type IN ('P')", @course.id]
     )
     @courseMaster = Profile.find(
      :first, 
      :include => [:participants], 
      :conditions => ["participants.object_id = ? AND participants.object_type='Course' AND participants.profile_type = 'M'", params[:id]]
      )
     render :partial => "/group/setup",:locals=>{:@course=>@course}         
  end 
   
  
  def show_course
    @course = Course.find_by_id(params[:id])
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    if !@profile.nil?
    @badges = AvatarBadge.select("count(*) as total").where("profile_id = ? and course_id = ?",@profile.id,@course.id)
    end
    xp = TaskGrade.select("sum(points) as total").where("school_id = ? and course_id = ? and profile_id = ?",@profile.school_id,@course.id,@profile.id)
    @course_xp = xp.first.total
    @peoples = Profile.find(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.object_id = ? AND participants.object_type IN ('Course','Group') AND participants.profile_type IN ('P', 'S')", @course.id]
    )
    @member_count = @peoples.length
    @pending_count = Profile.count(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.object_id = ? AND participants.object_type IN ('Course','Group') AND participants.profile_type IN ('P')", @course.id]
    )
    @courseMaster = Profile.find(
      :first, 
      :include => [:participants], 
      :conditions => ["participants.object_id = ? AND participants.object_type='Course' AND participants.profile_type = 'M'", params[:id]]
      )
    @groups = Group.find(:all, :conditions=>["course_id = ?",params[:id]])
    @totaltask = Task.find(:all, :conditions =>["course_id = ?",@course.id])
    if params[:section_type]=="C"
    @course_messages = Message.find(:all,:conditions=>["parent_id = ? AND parent_type = 'C'",@course.id],:order => "created_at DESC" )
    elsif params[:section_type]=="G"
    @course_messages = Message.find(:all,:conditions=>["profile_id = ? AND parent_id = ? AND parent_type = 'G'",user_session[:profile_id],@course.id],:order => "created_at DESC" )
    end
    #@totaltask = Task.joins(:participants).where(["profile_id =?",user_session[:profile_id]])
    if params[:value] && !params[:value].nil?  
      if (params[:section_type] == "G" && params[:value] == "1")
        render:partial => "/group/group_wall" 
      elsif params[:value] == "1" 
        render:partial => "/course/show_course"  
      elsif params[:value] == "3" 
        render :partial => "/course/forum",:locals=>{:@groups=>@groups}
      elsif params[:value] == "4"
        render :partial => "/course/files"       
      elsif params[:value] == "5"
        render :partial => "/course/stats"                     
      end  
    end
    end
      

   def view_member
     @course = Course.find_by_id(params[:id])
     if params[:section_type] == 'G'
        section_type = 'Group'
     else   
        section_type = 'Course'
     end   
     @peoples = Profile.find(
       :all, 
       :include => [:participants], 
       :conditions => ["participants.object_id = ? AND participants.object_type= ? AND participants.profile_type IN ('P', 'S')", @course.id,section_type]
     )
     render :partial => "/course/member_list",:locals=>{:course=>@course}         
   end

   def view_setup
     @course = Course.find_by_id(params[:id])
     render :partial => "/course/setup",:locals=>{:course=>@course}         
   end   
  
  def add_file
    school_id = params[:school_id]
    course_id = params[:id]
    @vault = Vault.find(:first, :conditions => ["object_id = ? and object_type = 'School' and vault_type = 'AWS S3'", school_id])
    if @vault
      @attachment = Attachment.new(:resource=>params[:file], :object_type=>"Course", :object_id=>course_id, :school_id=>school_id, :owner_id=>user_session[:profile_id])
      if @attachment.save
        @url = @attachment.resource.url
      end
    end
    render :partial => "/course/file_list" ,:locals=>{:a => @attachment}
  end
  
  def course_stats
    if params[:id] && !params[:id].nil?
      @grade = []
      @points = []
      @course = Course.find(params[:id])
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      @likes = Like.where("course_id = ?",@course.id)
      #@participant = Participant.all( :joins => [:profile], :conditions => ["participants.object_id=? AND participants.profile_type = 'S' AND object_type = 'Course'",@course.id],:select => ["profiles.full_name,participants.id,participants.profile_id"])
      @course_grade, oc = CourseGrade.load_grade(@profile.id, @course.id,@profile.school_id)
      if !@course_grade.nil?
        @course_grade.each do |key , val|
          @grade.push(val)
          letter = GradeType.value_to_letter(val, @profile.school_id)
          @grade.push(letter)
        end
      end
      @outcomes = @course.outcomes
      if !@outcomes.nil?
         @points , @course_xp = CourseGrade.get_outcomes(@course.id,@outcomes,@profile.school_id,@profile.id) 
      end
      if !@profile.nil?
        badge_ids = AvatarBadge.find(:all, :select => "badge_id", :conditions =>["profile_id = ? and course_id = ?",@profile.id,@course.id]).collect(&:badge_id)
        @badge = Badge.where("id in (?)",badge_ids).order("created_at desc")
      end
      render :partial =>"/course/course_stats"
    end  
  end
  
  def top_achivers
    if params[:outcome_id] && !params[:course_id].nil?
       @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
       @students = Course.get_top_achievers(@profile.school_id,params[:course_id], params[:outcome_id])
       render :partial =>"/course/top_achivers"
    end    
  end
  
  def toggle_priority_file
    if params[:id] and !params[:id].nil?
      @att = Attachment.find(params[:id])
      if !@att.nil?

        @att.update_attribute('starred',(@att.starred == true ? false : true))
      end
      render :text => {:starred => @att.starred }.to_json
    end
  end

  
  def filter
    if params[:filter] && !params[:filter].nil?
       @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
       if params[:section_type] && ! params[:section_type].nil?
         if  params[:section_type] =="C"
          @courses = Course.course_filter(@profile.id,params[:filter])
         elsif params[:section_type] =="G"
          @courses = Course.all_group(@profile,params[:filter])
         end
      end
       render :partial => "/course/content_list",:locals=>{:section_type=> params[:section_type]}
    end
  end
    
  def set_archive
    if params[:id] && !params[:id].nil?
      @course = Course.find(params[:id])
      if @course
        @course.update_attribute('archived',true)
        render :json => {:status => "Success"}
      end
    end
  end
end