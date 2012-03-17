class GroupController < ApplicationController
  
  def index
    if params[:search_text]
      search_text =  "#{params[:search_text]}%"
      @groups = Group.find(
        :all, 
        :conditions => ["(groups.name LIKE ?)",search_text]
      )
    else 
      @groups = Group.find(:all)
    end
      respond_to do |wants|
        wants.html do
          if request.xhr?
            render :partial => "/group/list"
          else
            render
          end
        end
      end
  end
  
  def new
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/group/form"
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
    @group.save
    render :text => {"sinfo"=>@group}.to_json
  end

  def show
    @group = Group.find(params[:id])
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/group/form"
        else
          render
         end
       end
     end
   end
   
end