class ScreenShot < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :game
  has_attached_file :image,
                    path: 'screen_shots/:id/:filename',
                    default_url: '/assets/:style/missing.jpg'
  # FIXME: https://stackoverflow.com/a/21898204/14269772
  do_not_validate_attachment_file_type :image
end
