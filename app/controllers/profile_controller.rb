class ProfileController < ApplicationController
  
  def index
  end

  def show
    id = params[:id]
    if id.nil?
      @profile = Profile.new
      @profile.avatar = Avatar.new
      @profile.avatar.skin = 3
      @profile.avatar.body = "avatar/body/body_3.png"
      @profile.avatar.head = "avatar/head/heart_3.png"
      @profile.avatar.hair = "avatar/hair/short_wavy_3.png"
      @profile.avatar.top = "basic/tops/shirt_short_sleeve_cyan.png"
      @profile.avatar.bottom = "basic/bottoms/trousers_long_brown.png"
      @profile.avatar.shoes = "basic/shoes/sneakers_gray.png"
    end
  end

  def new
  end

  def edit
    wardrobe_items = WardrobeItem.find(:all, 
      :conditions => ["archived = ?", false],
      :order => "depth, sort_order")
    
    render :text => wardrobe_items.to_json
  end
end
