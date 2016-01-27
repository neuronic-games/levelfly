class BadgeImage < ActiveRecord::Base
  has_attached_file :image

  @@base_url = "/images/badges"
  cattr_accessor :base_url
  
  def image_file_path
    return BadgeImage.base_url + "/" + self.image_file_name
  end
end
