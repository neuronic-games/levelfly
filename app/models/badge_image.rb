class BadgeImage < ActiveRecord::Base
  has_one_attached :image

  has_one :available_badge, class_name: 'Badge', foreign_key: 'available_badge_image_id'
  has_one :uploaded_badge, class_name: 'Badge'

  @@base_url = '/images/badges'
  cattr_accessor :base_url

  def image_file_path
    if image.attached?
      url_for(image)
    elsif image_file_name && (image_file_name =~ /http/) == 0
      image_file_name
    else
      ENV.fetch('URL', nil) + BadgeImage.base_url + '/' + image_file_name.to_s
    end
  end

  def self.available_image_by_badge(id)
    badge_image = BadgeImage.find_by_id(id)
    if badge_image&.image&.attached?
      url_for(badge_image.image)
    else
      BadgeImage.base_url + '/' + badge_image.try(:image_file_name).to_s
    end
  end

  def self.blank
    ENV.fetch('URL', nil) + BadgeImage.base_url + '/images/badges/blank.png'
  end
end
