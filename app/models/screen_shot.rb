class ScreenShot < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :game
  has_attached_file :image,
    :storage => :s3,
    :s3_credentials => { :access_key_id => ENV['S3_KEY'], :secret_access_key => ENV['S3_SECRET'] },
    :path => "screen_shots/:id/:filename",
    :bucket => ENV['S3_PATH'],
    :s3_protocol => ENV['S3_PROTOCOL'],
    :default_url => "/assets/:style/missing.jpg"

end
