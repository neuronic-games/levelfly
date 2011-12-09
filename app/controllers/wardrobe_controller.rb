class WardrobeController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
  def index
    @wardrobe_item_lvel_0 = WardrobeItem.find(:all, :conditions=>["depth = 0"])
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
    id = params[:id]
  end

  def new
    respond_to do |wants|
      wants.html do
        if params[:id] && !params[:id].empty?
          @wardrobe_item_id = params[:id]
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
      @wardrobe_items = WardrobeItem.find(:all, :conditions=>["parent_item_id = ?", params[:wardrobe_item_id]])
      render :partial => "/wardrobe/wardrobe_items"
    else
      render :nothing => true
    end
  end
end
