class Course < ActiveRecord::Base
  belongs_to :school
  has_many :participants, :as => :object
  has_many :messages, :as => :parent
  has_many :categories
  has_many :outcomes
  has_many :attachments, :as => :object
  has_attached_file :image,
    :storage => :s3,
    :s3_credentials => { :access_key_id => school.vault.account, :secret_access_key => school.vault.secret },
    :path => "schools/:school/courses/:id/:filename",
    :bucket => school.vault.folder
end
