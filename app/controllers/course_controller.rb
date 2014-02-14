class CourseController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
        require 'digest/sha1'
  before_filter :check_role,:only=>[:new, :save]
      
  def index
    if params[:section_type]
      section_type = params[:section_type]
    else
      section_type = "C"
    end
    
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    
    if params[:search_text]
      search_text =  "%#{params[:search_text]}%"
      if section_type == "C"
        @courses = Course.find(
          :all,
          :include => [:participants], 
          :conditions => ["(lower(courses.name) LIKE ? OR lower(courses.code) LIKE ?) and parent_type = ? and school_id = ? and removed = ?", search_text.downcase, search_text.downcase, Course.parent_type_course, @profile.school_id, false])
      
      elsif section_type == "G"
        @courses = Course.find(:all, :conditions=>["(lower(courses.name) LIKE ? OR lower(courses.code) LIKE ?) and parent_type = ? and school_id = ? and removed = ?",search_text.downcase,search_text.downcase, Course.parent_type_group, @profile.school_id, false])
      end
     
    else

      # Check if the user was working on a details page before, and redirect if so
      return if redirect_to_last_action(@profile, 'course', '/course/show')
      
      if !section_type.nil?
        if section_type == 'C'
          @courses = Course.course_filter(@profile.id,"")
        end
        if section_type == 'G'
          @user_group = false
          @courses = Course.all_group(@profile,"M")
        end
      else
        @courses = []
      end
    end
    @profile.record_action('course', section_type)
    @profile.record_action('last', 'course')
    @section_type = section_type
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
      @profile = Profile.find(user_session[:profile_id])
      @participant =  participant = Participant.find(:first, :conditions => ["target_id = ? AND target_type = 'Course' AND profile_id = ? ", params[:id], user_session[:profile_id]])
      @owner = Participant.find(:first, :conditions => ["target_id = ? AND target_type = 'Course' AND profile_type ='M'", params[:id]])
      if !@participant 
        @participant = Participant.new
        @participant.target_id    = params[:id] if params[:id]
        @participant.profile_id   = user_session[:profile_id]
        @participant.target_type  = "Course" # Change 'Group' to 'Course' because of query include `participants`.`target_type` = 'Course' when load group or course! Change by vaibhav
        @participant.profile_type = "P"  
        if @participant.save
          status = true
          wall_id = Wall.get_wall_id(params[:id],"Course")
            Feed.create(
              :profile_id => user_session[:profile_id],
              :wall_id =>wall_id
            )
            #@message.content ="Please accept my group invitation (#{@course.code_section})."
            content ="#{@profile.full_name} has requested to become a member of #{@course.name}"
            message_type = "group_request"
            @message = Message.send_course_request(user_session[:profile_id],@owner.profile_id, wall_id, params[:id],"Course",message_type,content)
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
    @badges = AvatarBadge.where("profile_id = ? and course_id = ?",@profile.id,@course.id).count
    end
    xp = TaskGrade.select("sum(points) as total").where("school_id = ? and course_id = ? and profile_id = ?",@profile.school_id,@course.id,@profile.id)
    @course_xp = xp.first.total
    @member_count = Profile.count(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'S'", @course.id]
    )
    @member = Participant.find( :first, :conditions => ["participants.target_id = ? AND participants.profile_id = ? AND participants.target_type='Course' AND participants.profile_type IN ('M', 'S')", @course.id, @profile.id])
    @pending_count = Profile.count(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type IN ('P')", @course.id]
    )
    @courseMaster = Profile.find(
      :first, 
      :include => [:participants], 
      :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", @course.id]
      )
    @course_owner = Participant.find(:first, :conditions=>["target_id = ? AND profile_type = 'M' AND target_type='Course'",params[:id]])   
    #@totaltask = Task.find(:all, :conditions =>["course_id = ?",@course.id])
    @totaltask = @tasks = Task.filter_by(user_session[:profile_id], @course.id, "current")
    @groups = Group.find(:all, :conditions=>["course_id = ?",@course.id])
     message_ids = MessageViewer.find(:all, :select => "message_id", :conditions =>["viewer_profile_id = ?", @profile.id]).collect(&:message_id)
    if params[:section_type]=="C"
      @course_messages = Message.find(:all,:conditions=>["parent_id = ? AND parent_type = 'C' and id in(?)",@course.id,message_ids],:order => "starred DESC, post_date DESC" )
    elsif params[:section_type]=="G"
      message_ids = MessageViewer.find(:all, :select => "message_id").collect(&:message_id) if @member.nil?
      @course_messages = Message.find(:all,:conditions=>["parent_id = ? AND parent_type = 'G' and id in (?)",@course.id,message_ids],:order => "starred DESC, post_date DESC" )
    end
    @profile.record_action('course', @course.id)
    @profile.record_action('last', 'course')
    #ProfileAction.add_action(@profile.id, "/course/show/#{@course.id}?section_type=#{params[:section_type]}") 
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
    @course.name = params[:course].slice(0,64) if params[:course]
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
    @course.post_messages = params[:post_messages] if params[:post_messages]
		@course.show_grade = params[:show_grade] if params[:show_grade]
		@course.semester = params[:semester] if params[:semester]
		@course.year = params[:year] if params[:year]
           
    if params[:file]
      @course.image.destroy if @course.image
      @course.image = params[:file]
    end
    
    if @course.save
      #get wall id
      wall_id = Wall.get_wall_id(@course.id,"Course")
      #Save categories
      if params[:categories] && !params[:categories].empty?
        categories_array = params[:categories]
        loaded_categories_array = params[:percent_value]
        categories_array.each_with_index do |category,i|
          @category = Category.create(
            :name=> category,
            :percent_value=> loaded_categories_array[i],
            :course_id=> @course.id,
            :school_id=> @course.school_id
          )
        end
      end
      #for add shared outcomes to new course have same course code
      if @course.outcomes.count==0
        @same_code_courses = Course.find(:all, :conditions=>["code = ? AND id != ?",@course.code, @course.id])
        if @same_code_courses
          @same_code_courses.each do |same_course|
            same_course.outcomes.where(["shared = ?", true]).each do |same_outcome|
              shared = true
              if @course.outcomes.count>0
                @course.outcomes.each do |o|
                  if o.id == same_outcome.id
                    shared = false
                    break
                  end
                end
              end
              if shared==true
                @course.outcomes << same_outcome
              end
            end
          end
        end

      end

      #Save outcomes
      if params[:outcomes] && !params[:outcomes].empty?
        outcomes_array = params[:outcomes]
        outcomes_descs_array = params[:outcomes_descr]
        outcomes_share_array = params[:outcome_share]
        outcomes_array.each_with_index do |outcome,i|
          @outcome = Outcome.create(
            :name=> outcome,
            :descr=> outcomes_descs_array[i],
            :school_id=> @course.school_id,
            :shared=> outcomes_share_array[i],
            :created_by=> @course.id
          )
          @course.outcomes << @outcome
        end
      end
      
      # Participant record for master
      participant = Participant.find(:first, :conditions => ["target_id = ? AND target_type='Course' AND profile_id = ?", @course.id, user_session[:profile_id]])
      if !participant
        @participant = Participant.new
        @participant.target_id = @course.id
        @participant.target_type = "Course"
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
		message_type = nil
    content = nil
		resend = false
    if params[:email]
      #if params[:section_type] == 'G'
       #    section_type = 'Group'
      #end   
      #if params[:section_type] == 'C'
       #  section_type = 'Course'
      #end 
      # Change 'Group' to 'Course' because of query include `participants`.`target_type` = 'Course' when load group or course! Change by vaibhav
      section_type = 'Course'
      @user = User.find(:first, :conditions => ["lower(email) = ?", params[:email].downcase])
      if @user 
        @profile = Profile.find_by_user_id(@user.id)
      else  
        @user, @profile = User.new_user(params[:email],school.id)
        new_user = true
      end
      if @profile
        participant_exist = Participant.find(:first, :conditions => ["target_id = ? AND target_type= ? AND profile_id = ?", params[:course_id], section_type, @profile.id])
        course = Course.find(params[:course_id])
        if !participant_exist
          @participant = Participant.new
          @participant.target_id = params[:course_id]
          @participant.target_type = section_type
          @participant.profile_id = @profile.id
          @participant.profile_type = "P"
          if @participant.save
            wall_id = Wall.get_wall_id(params[:course_id],"Course")
            Feed.create(
              :profile_id => @profile.id,
              :wall_id =>wall_id
            )
            # Send a message. It may also send an email.
             if params[:section_type] == 'G'
               message_type = "group_invite"
               content = "You are invited to join the group: #{course.name}."
             elsif params[:section_type] == 'C'
               message_type = "course_invite"
               content = "Please join #{course.name} (#{course.code_section})."
             end
            @message = Message.send_course_request(user_session[:profile_id], @profile.id, wall_id, params[:course_id],section_type,message_type,content)
						send_email(@user.id,params[:course_id],@message.id,new_user)     
            status = true           
          end
        else 
					if participant_exist.profile_type == "P"
						wall_id = Wall.get_wall_id(params[:course_id],"Course")
						if params[:section_type] == 'G'
							message_type = "group_invite"
							content = "You are invited to join the group: #{course.name}."
						elsif params[:section_type] == 'C'
							message_type = "course_invite"
							content = "Please join #{course.name} (#{course.code_section})."
						end
						@message = Message.send_course_request(user_session[:profile_id], @profile.id, wall_id, params[:course_id],section_type,message_type,content)
						send_email(@user.id,params[:course_id],@message.id,new_user)
						resend = true
					else
						already_added = true
					end
        end
      end
      render :text => {"status"=>status, "already_added" => already_added,"profile" =>@profile,"user"=>@user,"new_user"=>new_user, "resend"=>resend}.to_json
   end
  end
  
  def send_email(email,course,message_id,new_user)
     @course = Course.find(course)
     @current_user = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
     @school = School.find(@current_user.school_id)
     link = "#{email}&#{message_id}"
     @link = Course.hexdigest_to_string(link)
     #@link = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('md5'), "123456", link)
     UserMailer.registration_confirmation(email,@current_user,@course,@school,message_id,@link,new_user).deliver
  end
	
	# Send email to all participants via course group and forum memberlist
	def send_email_to_all_participants
		status = false
		section_type = 'Course' #TO DO : Need to done for forum and groups also
		post_message = params[:post_message] == "true" ? true : false if params[:post_message]
		@course = Course.find(params[:id])
		if @course
			@peoples = Profile.find(
         :all, 
         :include => [:participants], 
         :conditions => ["participants.target_id = ? AND participants.target_type= ? AND participants.profile_type in ('S', 'M')", @course.id,section_type]
       )
			
			if post_message and post_message == true
  			wall_id = Wall.get_wall_id(params[:id], params[:section_type]) #params[:wall_id]
        @message = Message.new
        @message.profile_id = user_session[:profile_id]
        @message.parent_id = params[:id] #params[:target_id]
        @message.parent_type = params[:section_type] 
        @message.content = CGI::unescape(params[:mail_msg]) if params[:mail_msg]
        @message.target_id = params[:id]
        @message.target_type = params[:section_type]
        @message.message_type = params[:message_type] if params[:message_type]
        @message.wall_id = wall_id
        @message.post_date = DateTime.now
        @message.save
        @message_viewer = MessageViewer.add(user_session[:profile_id],@message.id,params[:section_type],params[:id])
        @feed = Feed.find(:first,:conditions=>["profile_id = ? and wall_id = ?",user_session[:profile_id],wall_id])
        if @feed.nil?
          Feed.create(:profile_id => user_session[:profile_id],:wall_id =>wall_id)
        end
			end
			
			if @peoples
				@msg_content = CGI::unescape(params[:mail_msg])
				@current_user = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
				#threads = []
				@peoples.each do |people|
					#threads << Thread.new do
          Message.save_message(@current_user,people,"Profile",@msg_content,"Message",@course)
          #end
				end
				#threads.each(&:join)
				status = true
			end
		end
		render :text => {status:status}
	end
    
  def delete_participant
    status = false
    if params[:profile_id] && params[:course_id]
      participant = Participant.find(:first, :conditions => ["target_id = ? AND target_type = 'Course' AND profile_id = ? ", params[:course_id], params[:profile_id]])
      if participant
        participant.delete
        @wall_id = Wall.find(:first, :conditions=>["parent_id = ? and parent_type = 'C'",params[:course_id]])
        if !@wall_id.nil?
          @feed = Feed.find(:first, :conditions=>["profile_id = ? and wall_id = ? ",params[:profile_id],@wall_id.id])
          if !@feed.nil?
            @feed.delete
          end
        end
        forum = Course.find(:all, :conditions => ["course_id = ?",params[:course_id]])
        if forum
          forum.each do |forum|
            forum_participant = Participant.find(:first, :conditions => ["target_id = ? AND target_type = 'Course' AND profile_id = ? ", forum.id, params[:profile_id]])
            if forum_participant
              forum_participant.delete
              wall_id = Wall.find(:first, :conditions=>["parent_id = ? and parent_type = 'C'",forum.id])
              if !wall_id.nil?
                feed = Feed.find(:first, :conditions=>["profile_id = ? and wall_id = ? ",params[:profile_id],wall_id.id])
                if !feed.nil?
                  feed.delete
                end
              end
            end
          end
        end
        task = Task.find(:all, :conditions => ["course_id = ?",params[:course_id]])
        if task
          task.each do |task|
            task_participant = TaskParticipant.find(:first, :conditions => ["task_id = ? AND profile_id = ? AND profile_type = 'M'",task.id, params[:profile_id]])
            if task_participant
              task_participant.delete
              wall_id = Wall.find(:first, :conditions=>["parent_id = ? and parent_type = 'Task'",task.id])
              if !wall_id.nil?
                feed = Feed.find(:first, :conditions => ["profile_id = ? and wall_id = ? ",params[:profile_id], wall_id.id])
                if !feed.nil?
                  feed.delete
                end
              end
            end
          end
        end
        status = true
        User.delete_pending_user(params[:profile_id])
      end
    end
    render :text => {"status"=>status}.to_json
  end
  
  def remove_course_outcomes
    if params[:outcomes] && !params[:outcomes].nil?
      if Outcome.find(params[:outcomes]).shared == true && !params[:course_id].nil?
        @course = Course.find(params[:course_id])
        @course.outcomes.destroy(params[:outcomes]) if @course
      else
        Outcome.destroy(params[:outcomes])
      end
      render :text => {"status"=>"true"}.to_json
    end
  end
  
  def remove_course_files
    if params[:files] && !params[:files].nil?
      Attachment.destroy(params[:files])
      render :text => {"status"=>"true"}.to_json
    end
  end
  
  def share_outcome
    if params[:course_id] and !params[:course_id].nil?
      @outcome = Outcome.find(params[:outcome_id])
      if @outcome
        @outcome.shared = true
        @outcome.save
        render :text => {"status"=>"true"}.to_json
      end
    end
  end
  
  def update_course_outcomes
    if params[:outcome_id] && !params[:outcome_id].empty?
      outcome = Outcome.find(params[:outcome_id])
      outcome.name = params[:outcome] if params[:outcome] && !params[:outcome].empty?
      outcome.descr = params[:outcome_descr] if params[:outcome_descr] && !params[:outcome_descr].empty?
      outcome.save
    end
    render :nothing =>true
  end
  
  def update_course_categories
    if params[:category_id] && !params[:category_id].empty?
      category = Category.find(params[:category_id])
      category.name = params[:category] if params[:category] && !params[:category].empty?
      category.percent_value = params[:category_value] if params[:category_value] && !params[:category_value].empty?
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
  # load shared outcomes
  def check_outcomes
    @outcomes = []
    @course = nil
    @for_course = Course.find(params[:id]) if params[:id] && !params[:id].nil?
    if @for_course && @for_course.outcomes
      @for_course.outcomes.each do |oc|
        @outcomes << oc
      end
    end
    params[:code] = params[:code].upcase
    if params[:code] && !params[:code].nil?
      params[:code] = params[:code].upcase
      @courses = Course.find(:all, :conditions =>["code = ?", params[:code]], :order => "created_at")
      if @courses.length > 0
          @courses.each do |course|
            @course = course if @course.nil?
            unless @for_course && @for_course.id == course.id
              course.outcomes.where(["shared = ?", true]).each do |value|
              shared = true
                if @outcomes.count>0
                   @outcomes.each do |o|
                    if o.id == value.id
                      shared = false
                      break
                    end
                  end
                end
                if shared==true
                  @outcomes << value
                end
              end 
            end
          end
          render :partial => "/course/show_outcomes",:locals=>{:outcomes=>@outcomes}
      else
        if @for_course && @outcomes
          render :partial => "/course/show_outcomes",:locals=>{:outcomes=>@outcomes}
        else
          render :text=>""
        end         
      end
    end
  end
  
  def view_group_setup
    
     @course = Course.find_by_id(params[:id])
     @member_count = Profile.count(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type IN ('M', 'S')", @course.id]
      )
      @pending_count = Profile.count(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type IN ('P')", @course.id]
     )
     @courseMaster = Profile.find(
      :first, 
      :include => [:participants], 
      :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", params[:id]]
      )
     render :partial => "/group/setup",:locals=>{:@course=>@course}         
  end 
   
  
  def show_course
    @course = Course.find(params[:id])
    @files = @course.attachments.order("starred desc,resource_file_name asc")
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    if !@profile.nil?
    @badges = AvatarBadge.where("profile_id = ? and course_id = ?",@profile.id,@course.id).count
    end
    xp = TaskGrade.select("sum(points) as total").where("school_id = ? and course_id = ? and profile_id = ?",@profile.school_id,@course.id,@profile.id)
    @course_xp = xp.first.total
    @peoples = Profile.find(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.target_id = ? AND participants.target_type IN ('Course','Group') AND participants.profile_type = 'S'", @course.id]
    )
    @member_count = @peoples.length
    @member = Participant.find(:first, :conditions => ["participants.target_id = ? AND participants.profile_id = ? AND participants.target_type='Course' AND participants.profile_type IN ('M', 'S')", @course.id, @profile.id]
)
    @pending_count = Profile.count(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.target_id = ? AND participants.target_type IN ('Course','Group') AND participants.profile_type IN ('P')", @course.id]
    )
    @courseMaster = Profile.find(
      :first, 
      :include => [:participants], 
      :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", params[:id]]
      )
    @groups = nil# Group.find(:all, :conditions=>["course_id = ?",params[:id]])
    enable_forum = false
    @totaltask = @tasks = Task.filter_by(user_session[:profile_id], @course.id, "current")
    message_ids = MessageViewer.find(:all, :select => "message_id", :conditions =>["viewer_profile_id = ?", @profile.id]).collect(&:message_id)
    if params[:section_type]=="C"
      @course_messages = Message.find(:all,:conditions=>["parent_id = ? AND parent_type = 'C' and id in(?)",@course.id,message_ids],:order => "starred DESC,created_at DESC" )
    elsif params[:section_type]=="G"
       message_ids = MessageViewer.find(:all, :select => "message_id").collect(&:message_id) if @member.nil?
      @course_messages = Message.find(:all,:conditions=>["parent_id = ? AND parent_type = 'G' and id in (?)",@course.id,message_ids],:order => "starred DESC,created_at DESC" )
    end
     if params[:value] == "3"
         setting = Setting.find(:first, :conditions=>["target_id = ? and value = 'true' and target_type ='school' and name ='enable_course_forums' ",@course.school_id])
       if setting and !setting.nil?
        @groups = @course.course_forum(@profile.id)
        enable_forum = true
       end
     end
    #@totaltask = Task.joins(:participants).where(["profile_id =?",user_session[:profile_id]])
    if params[:value] && !params[:value].nil?  
      if (params[:section_type] == "G" && params[:value] == "1")
        render:partial => "/group/group_wall" 
      elsif params[:value] == "1" 
        render:partial => "/course/show_course"  
      elsif params[:value] == "3" 
        render :partial => "/course/forum",:locals=>{:@groups=>@groups, :enable_forum => enable_forum}
      elsif params[:value] == "4"
        render :partial => "/course/files"       
      elsif params[:value] == "5"
        render :partial => "/course/stats"                     
      end  
    end
    end
      

   def view_member
     @course = Course.find_by_id(params[:id])
     # if params[:section_type] == 'G'
        # section_type = 'Group'
     # else   
        # section_type = 'Course' 
     # end   
     # Change 'Group' to 'Course' because of query include `participants`.`target_type` = 'Course' when load groups or courses! Change by vaibhav
     @profile = Profile.find(user_session[:profile_id])
     section_type = 'Course'
     @courseMaster = Profile.find(
      :first, 
      :include => [:participants], 
      :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M' and profile_id = ? ", @course.id,user_session[:profile_id]]
      )
     unless @courseMaster and @course.course_id != 0
       @people_pending = Profile.find(
       :all, 
       :include => [:participants, :user], 
       :conditions => ["participants.target_id = ? AND participants.target_type= ? AND participants.profile_type IN ('P')", @course.id,section_type],
       :order => "full_name, email"
       )
     end
     @peoples = Profile.find(
       :all, 
       :include => [:participants, :user], 
       :conditions => ["participants.target_id = ? AND participants.target_type= ? AND participants.profile_type IN ('S')", @course.id,section_type],
       :order => "full_name, email"
       )
     #ProfileAction.add_action(@profile.id, "/course/show/#{@course.id}?section_type=#{params[:section_type]}") 
     render :partial => "/course/member_list",:locals=>{:course=>@course}         
   end

   def view_setup
     @course = Course.find_by_id(params[:id])
     render :partial => "/course/setup",:locals=>{:course=>@course}         
   end   
  
  def add_file
    school_id = params[:school_id]
    course_id = params[:id]
    if params[:target_type] == 'Course'
      @course = Course.find(params[:id])
    elsif
      task = Task.find(params[:id])
      @course = task.course
    end
    @profile = Profile.find(params[:profile_id])
    #@vault = Vault.find(:first, :conditions => ["target_id = ? and target_type = 'School' and vault_type = 'AWS S3'", school_id])
    #if @vault
      @attachment = Attachment.new(:resource=>params[:file], :target_type=>params[:target_type], :target_id=>course_id, :school_id=>school_id, :owner_id=>user_session[:profile_id])
      if @attachment.save
        @url = @attachment.resource.url
        puts"#{@url}--#{params[:target_type]}"
      end
    #end
    render :partial => "/course/file_list" ,:locals=>{:a => @attachment}
  end
  
  def download
    if params[:id] and !params[:id].blank?
      @attachment = Attachment.find(params[:id])
      if @attachment
        render :partial => "/course/download_dialog" ,:locals=>{:a => @attachment, :request_type=>params[:request_type]}
      end
      
    end
   # upload = Attachment.find(params[:id])
    # send_file upload.resource.url,
    # :filename => upload.resource_file_name,
    # :type => upload.resource_content_type,
    # :disposition => 'attachment'

  end
  
  def course_stats
    if params[:id] && !params[:id].blank?
      @grade = []
      @points = []
      @badge = []
      @course = Course.find(params[:id])
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      course_ids = Course.find(:all,:conditions => ["course_id = ?",@course.id]).collect(&:id).push(@course.id)
      message_ids = Like.find(:all,:select => "message_id",:conditions => ["course_id in (?)",course_ids]).collect(&:message_id)
      message_ids = message_ids.uniq
      @likes = Message.find(:all,:select => "messages.like",:conditions => ["id IN (?) and profile_id = ? and archived = ?",message_ids,@profile.id,false]).collect(&:like).sum
      @course_grade, oc = CourseGrade.load_grade(@profile.id, @course.id,@profile.school_id)
      if !@course_grade.nil?
        @course_grade.each do |key , val|
          @grade.push(val)
          letter = GradeType.value_to_letter(val, @profile.school_id) if val
          @grade.push(letter)
        end
      end
      @outcomes = @course.outcomes.order('name')
      if !@outcomes.nil?
         @points , @course_xp = CourseGrade.get_outcomes(@course.id,@outcomes,@profile.school_id,@profile.id) 
      end
      if !@profile.nil?
        @badge = AvatarBadge.find(:all, :select => "id, badge_id", :conditions =>["profile_id = ? and course_id = ?",@profile.id,@course.id])
        #@task_grade = TaskGrade.where("school_id = ? and course_id = ? and profile_id = ?",@profile.school_id,@course ,@profile.id)
        @course_tasks = Task.sort_tasks(@profile.id,@course.id)
      end
      render :partial =>"/course/course_stats"
    end  
  end
  
  def top_achivers
    if params[:outcome_id] && !params[:course_id].blank?
       course = Course.find(params[:course_id])
       @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
       @students = Course.get_top_achievers(course.school_id,params[:course_id], params[:outcome_id])
       render :partial =>"/course/top_achivers"
    end    
  end
  
  def toggle_priority_file
    if params[:id] and !params[:id].blank?
      @att = Attachment.find(params[:id])
      if !@att.nil?

        @att.update_attribute('starred',(@att.starred == true ? false : true))
      end
      render :text => {:starred => @att.starred }.to_json
    end
  end

  def toggle_priority_message
    if params[:id] and !params[:id].blank?
      @msg = Message.find(params[:id])
      if !@msg.nil?
        @msg.update_attribute('starred',(@msg.starred == true ? false : true))
      end
      render :text => {:starred => @msg.starred }.to_json
    end
  end
  
  def filter
    if params[:filter] && !params[:filter].blank?
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
    if params[:id] && !params[:id].blank?
      @course = Course.find(params[:id])
      if @course
        @course.update_attribute('archived',true)
        @course.update_attribute('removed',true) if @course.parent_type == 'F'
        render :json => {:status => "Success"}
      end
    end
  end
  
  def load_files
    if params[:id] and !params[:id].blank?
        id = params[:id]
        @profile = Profile.find(params[:profile_id])
				@course = Course.find(params[:course_id])
				
        if id == "all"
					@files = @course.attachments.order("starred desc,resource_file_name asc")
        else
					@task = Task.find(params[:id])
					@task_owner = @task.task_owner
					# Course owner can see all the files related to the course and their tasks
					# even if the files are uploaded by other participents
					if @profile.id == @task_owner.id
						@files = @task.attachments.order("starred desc,resource_file_name asc")
					# but other users can see only those files which are uploaded by them via tasks
					else
						@files = @task.attachments.where("owner_id IN (?)", [@profile.id, @task_owner.id]).order("starred desc,resource_file_name asc")
					end
        end
    render :partial => "/course/load_files",:locals=>{:files=> @files}
    end
  end
  
  def removed
    status = nil
    if params[:id] and !params[:id].blank?
      @course = Course.find(params[:id])
      @owner = @course.owner
      if @owner and !@owner.nil? and @owner.id == user_session[:profile_id]
         @course.removed = true
         @course.save
         tasks = Task.filter_by(user_session[:profile_id], @course.id, "")
         tasks.each do |task|
           task.update_attribute('archived',true)
         end
         status = true
      else
         participant = Participant.find( :first, :conditions => ["participants.target_id = ? AND participants.profile_id = ? AND participants.target_type='Course' AND participants.profile_type = 'S'", @course.id, user_session[:profile_id]])
         participant.delete if participant
         status = true
      end
    end
    render :json=>{:status=>status}
  end
  
  def show_forum
    if params[:id] and !params[:id].blank?
      @course = Course.find(params[:id])
      @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      @peoples = Profile.find(
        :all, 
        :include => [:participants], 
        :conditions => ["participants.target_id = ? AND participants.target_type IN ('Course','Group') AND participants.profile_type IN ('P', 'S')", @course.id]
      )
      @member = Participant.find( :first, :conditions => ["participants.target_id = ? AND participants.profile_id = ? AND participants.target_type='Course' AND participants.profile_type IN ('M', 'S')", @course.id, @profile.id])
      @member_count = @peoples.length
      @courseMaster = @course.owner
      message_ids = MessageViewer.find(:all, :select => "message_id", :conditions =>["viewer_profile_id = ?", @profile.id]).collect(&:message_id)
      @course_messages = Message.find(:all,:conditions=>["parent_id = ? AND parent_type = 'F' and id in(?)",@course.id,message_ids],:order => "starred DESC, post_date DESC" )
      render :partial => "/course/forum_wall"
    end
  end
  
  def new_forum
     @course = Course.create
     render :partial => "/course/forum_setup"
  end
  
  def save_forum
     if params[:id] && !params[:id].empty?
      @course = Course.find(params[:id])
    else
      @course = Course.new
    end
    @profile = Profile.find(user_session[:profile_id])
    @course.name = params[:name].slice(0,64) if params[:name]
    @course.descr = params[:descr] if params[:descr]
    @course.parent_type = "F"
    @course.code = params[:code].upcase if params[:code]
    @course.school_id =  @profile.school_id
    @course.course_id = params[:parent_id] if params[:parent_id]
    @course.post_messages = params[:post_messages] if params[:post_messages]
    if params[:file]
      @course.image.destroy if @course.image
      @course.image = params[:file]
    end
    if @course.save
      wall_id = Wall.get_wall_id(@course.id,"Course")
      participant = Participant.find(:first, :conditions => ["target_id = ? AND target_type='Course' AND profile_id = ?", @course.id, user_session[:profile_id]])
      if !participant
        @participant = Participant.new
        @participant.target_id = @course.id
        @participant.target_type = "Course"
        @participant.profile_id = user_session[:profile_id]
        @participant.profile_type = "M"
        if @participant.save
          Feed.create(
            :profile_id => user_session[:profile_id],
            :wall_id =>wall_id
          )
        end
      end
       @course.join_all(@profile)
      image_url = params[:file] ? @course.image.url : ""
    end
    render :json=> {:course=>@course, :image_url=>image_url}
  end
  
   def view_forum_setup 
     @course = Course.find_by_id(params[:id])
      render :partial => "/course/forum_setup"
   end
   
   def forum_member_unchecked
     status = false
     if params[:course_id] && !params[:course_id].nil?
       @course = Course.find(params[:course_id])
       wall_id = Wall.get_wall_id(@course.id,"Course")
       if params[:member_id] && !params[:member_id].nil?
         participant = Participant.find(:first, :conditions => ["target_id = ? AND target_type='Course' AND profile_id = ?", @course.id, params[:member_id]])
         if participant
           participant.delete
           status = true
         else
           @participant = Participant.new
           @participant.target_id = @course.id
           @participant.target_type = "Course"
           @participant.profile_id = params[:member_id]
           @participant.profile_type = "S"
           if @participant.save
             Feed.create(
               :profile_id => params[:member_id],
               :wall_id =>wall_id
             )
           end
           status = true
         end
       else
         if params[:check_val] == "false"
           @course.all_members = false
         else
           @course.all_members = true
           course_participants = Participant.find(:all, :conditions => ["target_id = ? AND target_type='Course' AND profile_type = 'S'", @course.course_id])
           course_participants.each do |participant|
             forum_participant = Participant.find(:first, :conditions => ["target_id = ? AND target_type='Course' AND profile_id = ?", @course.id, participant.profile_id])
             if forum_participant.nil? and params[:check_val] == "true" 
               @participant = Participant.new
               @participant.target_id = @course.id
               @participant.target_type = "Course"
               @participant.profile_id = participant.profile_id
               @participant.profile_type = "S"
               if @participant.save
                 Feed.create(
                   :profile_id => participant.profile_id,
                   :wall_id =>wall_id
                 )
               end
             end
           end
         end
         @course.save
         status = true
       end  
     end
     render :text => {"status"=>status}.to_json
   end

  def check_role
    section_type=""
    if params[:section_type] and !params[:section_type].nil?
      section_type = params[:section_type]
    elsif params[:parent_type] and !params[:parent_type].nil?
      section_type = params[:parent_type]
    end
    if Role.check_permission(user_session[:profile_id],section_type)==false
      render :text=>""
    end
  end
  
  def duplicate
    if params[:id]
      if course = Course.find(params[:id])
        course.delay.duplicate({:name_ext => "COPY"}, current_user)
        render :nothing => true, :status => 200
      end
    end
  end
end