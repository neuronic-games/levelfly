class BadgeImage < ActiveRecord::Base
  has_attached_file :image,
                    path: 'games/:id/:filename',
                    default_url: '/assets/:style/missing.jpg'

  # FIXME: https://stackoverflow.com/a/21898204/14269772
  do_not_validate_attachment_file_type :image

  # has_one :badge
  has_one :available_badge, class_name: 'Badge', foreign_key: 'available_badge_image_id'
  has_one :uploaded_badge, class_name: 'Badge', foreign_key: 'badge_image_id'

  @@base_url = '/images/badges'
  cattr_accessor :base_url

  def image_file_path
    # If the image is from S3, the path contains the full path
    return image_file_name if (image_file_name =~ /http/) == 0 # Starts with http

    # It's necessary to return the full URL with the domain name for external systems
    ENV.fetch('URL', nil) + BadgeImage.base_url + '/' + image_file_name
  end

  def self.available_image_by_badge(id)
    badge_image = BadgeImage.find_by_id(id)
    BadgeImage.base_url + '/' + badge_image.try(:image_file_name).to_s
  end

  def self.blank
    ENV.fetch('URL', nil) + BadgeImage.base_url + '/images/badges/blank.png'
  end
end
