class Profile < ActiveRecord::Base
  has_one :avatar
  belongs_to :major
  belongs_to :school
  belongs_to :user
  has_many :participants
  acts_as_taggable
  has_attached_file :image,
    :storage => :s3,
    :s3_credentials => { :access_key_id => ENV['S3_KEY'], :secret_access_key => ENV['S3_SECR'] },
    :path => "resources/:filename",
    :bucket => ENV['S3_BUCK']
end
