class BadgeImage < ActiveRecord::Base
  has_attached_file :image,
   :storage => :s3,
   :s3_credentials => { :access_key_id => ENV['S3_KEY'], :secret_access_key => ENV['S3_SECRET'] },
   :path => "games/:id/:filename",
   :bucket => ENV['S3_PATH'],
   :s3_protocol => ENV['S3_PROTOCOL'],
   :default_url => "/assets/:style/missing.jpg"
  
  has_one :badge
  @@base_url = "/images/badges"
  cattr_accessor :base_url
  
  def image_file_path
    return BadgeImage.base_url + "/" + self.image_file_name
  end


end
