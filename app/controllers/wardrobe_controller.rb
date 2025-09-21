class WardrobeController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  before_filter :check_role
  
  def index
    @wardrobe_item_lvel_0 = WardrobeItem.where(["depth = 0"]).order("sort_order")
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/wardrobe/list"
        else
          render
        end
      end
    end
  end
  
  def show
    if params[:id]
      @profile = Profile.where(["user_id = ?", current_user.id])
        .select("school_id")
        .first
      #@vault = Vault.find(:first, 
      #  :conditions => ["target_id = ? and target_type = 'School' and vault_type = 'AWS S3'", @profile.school_id])
      @wardrobe_item = WardrobeItem.find(params[:id])
      @wardrobe_id = @wardrobe_item.wardrobe_id
      respond_to do |wants|
        wants.html do
        @wardrobe_item_parent_id = @wardrobe_item.parent_item_id
          if request.xhr?
            render :partial => "/wardrobe/form"
          else
            render
          end
        end
      end
    end
  end

  def new
    @profile = Profile.where(["user_id = ?", current_user.id])
      .select("school_id")
      .first
    #@vault = Vault.find(:first, 
    #  :conditions => ["target_id = ? and target_type = 'School' and vault_type = 'AWS S3'", @profile.school_id])
    respond_to do |wants|
      wants.html do
        if params[:id] && !params[:id].empty?
          @wardrobe_item_parent_id = params[:id]
          @wardrobe_id = params[:wardrobe_id]
          if request.xhr?
            render :partial => "/wardrobe/form"
          else
            render
          end
        end
      end
    end
  end
  
  def save
    if params[:id] && !params[:id].empty?
      @wardrobe_item = WardrobeItem.find(params[:id])
    else
      # Save a new wardrboe item
      @wardrobe_item = WardrobeItem.new
    end
    @wardrobe_item.name = params[:wardrobe_item]
    @wardrobe_item.wardrobe_id = params[:wardrobe_id]
    @wardrobe_item.parent_item_id = params[:parent_id]
    @wardrobe_item.visible_date = params[:visible_date]
    @wardrobe_item.visible_level = params[:visible_level]
    @wardrobe_item.available_date = params[:available_date]
    @wardrobe_item.available_level = params[:available_level]
    @wardrobe_item.item_type = params[:item_type]
    @wardrobe_item.icon_file = params[:icon]
    @wardrobe_item.image_file = params[:image]
    @wardrobe_item.depth = params[:depth]
    @wardrobe_item.save
    render :text => {"wardrobe_item"=>@wardrobe_item}.to_json
    #redirect_to 'index'
  end
  
  def load_wardrobe_items
    if params[:wardrobe_item_id] && !params[:wardrobe_item_id].empty?
      @wardrobe_items = WardrobeItem.where(["parent_item_id = ?", params[:wardrobe_item_id]])
      .order("sort_order")
      render :partial => "/wardrobe/wardrobe_items"
    else
      render :nothing => true
    end
  end
  
  def save_sort_order
    status = 'false'
    if params[:item_ids] && !params[:item_ids].nil? 
      params[:item_ids].split(',').each_with_index do |wardrobe_id,index| 
        wardrobe_item = WardrobeItem.find(wardrobe_id)
        if wardrobe_item
          wardrobe_item.sort_order = index
          wardrobe_item.save
        end
      end
      status = 'true'
    end
    render :text => {"status"=>status}.to_json
  end
  
  def upload_wardrobe_image 
    tmp = params[:file]
    file_name = params[:name]
    school_id = params[:school_id]
    Attachment.aws_upload(school_id, file_name, tmp.path)
    render :nothing => true
  end
  
  def check_role
    if Role.check_permission(user_session[:profile_id],Role.modify_wardrobe)==false
      render :text=>""
    end
  end
  
end
