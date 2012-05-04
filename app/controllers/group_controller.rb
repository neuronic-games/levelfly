class GroupController < ApplicationController
  require 'group_helper'
  helper :all
  include GroupHelper
  
  def index
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    if params[:search_text]
      search_text =  "#{params[:search_text]}%"
      @groups = Group.find(
        :all, 
        :conditions => ["(groups.name LIKE ?)",search_text]
      )
    else 
	    if @profile
        user_session[:profile_id] = @profile.id
        user_session[:school_id] = @profile.school_id
        user_session[:profile_name] = @profile.full_name
        user_session[:profile_major] = @profile.major.name if @profile.major
        user_session[:profile_school] = @profile.school.code if @profile.school
        user_session[:vault] = @profile.school.vaults[0].folder if @profile.school
        #Set AWS credentials
        # set_aws_vault(@profile.school.vaults[0]) if @profile.school
      end
      @groups = Group.find(
        :all, 
        :include => [:participants], 
        :conditions => ["participants.profile_id = ?", @profile.id]
      )
      end
         respond_to do |wants|
         wants.html do
         if request.xhr?
         render :partial => "/shared/list"
         else
         render
        end
       end
   end
  end
  
   
   def new
   	if @task
      @task = Task.find(:first, :conditions=>["task_id = ?", current_task.id])
	  end
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/shared/group_form"
        else
          render
        end
      end
    end
  end
  
  
  def create
    if params[:id] && !params[:id].empty?
      @group = Group.find(params[:id])
    else
      @group = Group.new
    end	
    @group.name = params[:name] if params[:name]
    @group.descr = params[:descr] if params[:descr]
    @group.school_id = params[:school_id] if params[:school_id]
    @group.task_id = params[:task_id] if params[:task_id]
    @group.course_id = params[:course_id] if params[:course_id]
	
    if @group.save
      participant = Participant.find(:first, :conditions => ["object_id = ? AND object_type='Group' AND profile_id = ?", @group.id, user_session[:profile_id]])
      if !participant
        @participant = Participant.new
        @participant.object_id = @group.id
        @participant.object_type = "Group"
        @participant.profile_id = user_session[:profile_id]
        @participant.profile_type = "M"
        if @participant.save
          Feed.create(
            :profile_id => user_session[:profile_id]
          )
        end
      end	
    end
    render :text => {"group"=>@group}.to_json
  end
  
 def show
	 @group = Group.find(params[:id])
   @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
	 @wall = Wall.find(:first,:conditions=>["parent_id = ? AND parent_type='Group'", @group.id])
     @peoples = Profile.find(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.object_id = ? AND participants.object_type='Group' AND participants.profile_type = 'S'", @group.id]
     )
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/shared/group_form"
        else
          render
         end
       end
     end
   end
 
 def get_participants
	search_participants()
 end
   
  
  def add_participant
    status = false
    already_added = false
    if params[:profile_id] && params[:group_id]
      participant_exist = Participant.find(:first, :conditions => ["object_id = ? AND object_type= 'Group' AND profile_id = ?", params[:group_id], params[:profile_id]])
      if !participant_exist
        @participant = Participant.new
        @participant.object_id = params[:group_id]
        @participant.object_type = "Group"
        @participant.profile_id = params[:profile_id]
        @participant.profile_type = "S"
        if @participant.save
          wall_id = Wall.get_wall_id(params[:group_id],"Group")
          Feed.create(
            :profile_id => params[:profile_id],
            :wall_id =>wall_id
          )
          status = true
        end
      else 
          already_added = true
      end
    end
    render :text => {"status"=>status, "already_added" => already_added}.to_json
  end 
   
   def delete_participant
    status = false
    if params[:profile_id] && params[:group_id]
      participant = Participant.find(:first, :conditions => ["object_id = ? AND object_type = 'Group' AND profile_id = ? ", params[:group_id], params[:profile_id]]) 
      if participant
        participant.delete
        status = true
      end
    end
    render :text => {"status"=>status}.to_json
  end 
      
end
