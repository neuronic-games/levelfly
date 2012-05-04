class Course < ActiveRecord::Base
  belongs_to :school
  has_many :participants, :as => :object
  has_many :messages, :as => :parent
  has_many :categories
  has_many :outcomes
  has_many :attachments, :as => :object
  has_attached_file :image,
    :storage => :s3,
    :s3_credentials => { :access_key_id => school.vault[0].account, :secret_access_key => school.vault[0].secret },
    :path => "courses/:filename",
    :bucket => school.vault[0].folder
end
