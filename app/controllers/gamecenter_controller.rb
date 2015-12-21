class GamecenterController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!

  # Login the player to GameCenter
  def authenticate
    message = ""
    success = true
    
    return success, message
  end

  # Returns 50 top scores for your game
  def list
  end

  # Update the player's progress in the game
  def update
    message = ""
    success = true
    
    return success, message
  end

  # Returns the player's progress in the game
  def view
  end
  
end
