class ProfileController < ApplicationController
  def index
  end

  def show
    id = params[:id]
    if id.nil?
      @profile = Profile.new
      @profile.avatar = Avatar.new
      @profile.avatar.body = "body_3.png"
      @profile.avatar.head = "heart_3.png"
      @profile.avatar.hair = "short_wavy_3.png"
      @profile.avatar.top = "/basic/top/shirt_short_sleeve_cyan.png"
      @profile.avatar.bottom = "/basic/bottom/trousers_long_brown.png"
      @profile.avatar.shoes = "/basic/shoes/sneakers_gray.png"
    end
  end

  def new
  end

  def edit
  end
end
