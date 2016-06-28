class BadgeImage < ActiveRecord::Base
  has_attached_file :image,
   :storage => :s3,
   :s3_credentials => { :access_key_id => ENV['S3_KEY'], :secret_access_key => ENV['S3_SECRET'] },
   :path => "games/:id/:filename",
   :bucket => ENV['S3_PATH'],
   :s3_protocol => ENV['S3_PROTOCOL'],
   :default_url => "/assets/:style/missing.jpg"
  
  # has_one :badge
  has_one :available_badge, :class_name => "Badge", :foreign_key => "available_badge_image_id"
  has_one :uploaded_badge, :class_name => "Badge", :foreign_key => "badge_image_id"

  @@base_url = "/images/badges"
  cattr_accessor :base_url
  
  def image_file_path
    # If the image is from S3, the path contains the full path
    if (self.image_file_name =~ /http/) == 0  # Starts with http
      return self.image_file_name
    end

    # It's necessary to return the full URL with the domain name for external systems
    return ENV["URL"] + BadgeImage.base_url + "/" + self.image_file_name
  end

  def available_image_by_badge(id)
    badge_image = BadgeImage.find_by_id(id)
    return BadgeImage.base_url + "/" + badge_image.try(:image_file_name).to_s
  end

end
