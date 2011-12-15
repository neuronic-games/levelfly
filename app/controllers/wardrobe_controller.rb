class WardrobeController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
  def index
    @wardrobe_item_lvel_0 = WardrobeItem.find(:all, :conditions=>["depth = 0"] ,:order=>"sort_order")
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
      @profile = Profile.find(:first,  :select => "school_id", :conditions=>["user_id = ?", current_user.id])
      @vault = Vault.find(:first, 
        :conditions => ["object_id = ? and object_type = 'School' and vault_type = 'AWS S3'", @profile.school_id])
      @wardrobe_item = WardrobeItem.find(params[:id])
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
    @profile = Profile.find(:first,  :select => "school_id", :conditions=>["user_id = ?", current_user.id])
    @vault = Vault.find(:first, 
      :conditions => ["object_id = ? and object_type = 'School' and vault_type = 'AWS S3'", @profile.school_id])
    respond_to do |wants|
      wants.html do
        if params[:id] && !params[:id].empty?
          @wardrobe_item_parent_id = params[:id]
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
    @wardrobe_item.parent_item_id = params[:parent_id]
    @wardrobe_item.visible_date = params[:visible_date]
    @wardrobe_item.visible_level = params[:visible_level]
    @wardrobe_item.available_date = params[:available_date]
    @wardrobe_item.available_level = params[:available_level]
    @wardrobe_item.item_type = params[:item_type]
    @wardrobe_item.save
    render :text => {"wardrobe_item"=>@wardrobe_item}.to_json
  end
  
  def load_wardrobe_items
    if params[:wardrobe_item_id] && !params[:wardrobe_item_id].empty?
      @wardrobe_items = WardrobeItem.find(:all, :conditions=>["parent_item_id = ?", params[:wardrobe_item_id]], :order => "sort_order")
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
    Attachment.aws_upload(school_id, file_name, tmp)
    render :nothing => true
  end
  
end
