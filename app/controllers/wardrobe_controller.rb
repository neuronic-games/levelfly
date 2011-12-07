class WardrobeController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
  def show
    id = params[:id]
  end

  def new
    
  end
  
  def save
    if params[:id] && !params[:id].empty?
      @wardrobe_item = WardrobeItem.find(params[:id])
    else
      # Save a new wardrboe item
      @wardrobe_item = WardrobeItem.new
    end
    @wardrobe_item.name = params[:wardrobe_item]
    @wardrobe_item.visible_date = params[:visible_date]
    @wardrobe_item.visible_level = params[:visible_level]
    @wardrobe_item.available_date = params[:available_date]
    @wardrobe_item.available_level = params[:available_level]
    @wardrobe_item.item_type = params[:item_type]
    @wardrobe_item.save
    render :text => {"wardrobe_item"=>@wardrobe_item}.to_json
  end
end
