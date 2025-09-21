class BadgeImage < ActiveRecord::Base
  has_attached_file :image,
                    storage: :s3,
                    s3_credentials: { access_key_id: ENV.fetch('S3_KEY', nil),
                                      secret_access_key: ENV.fetch('S3_SECRET', nil) },
                    path: 'games/:id/:filename',
                    bucket: ENV.fetch('S3_PATH', nil),
                    s3_protocol: ENV.fetch('S3_PROTOCOL', nil),
                    default_url: '/assets/:style/missing.jpg'

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
