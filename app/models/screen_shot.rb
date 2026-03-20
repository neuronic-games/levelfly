class ScreenShot < ActiveRecord::Base
  belongs_to :game
  has_one_attached :image
end
