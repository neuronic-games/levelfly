class Group < ActiveRecord::Base
 belongs_to :school
 has_many :participants, :as => :object
 has_many :messages, :as => :parent
 
 has_attached_file :image,
    :storage => :s3,
    :s3_credentials => { :access_key_id => School.vault.account, :secret_access_key => School.vault.secret },
    :path => "schools/:school/courses/:course/group/:id/:filename",
    :bucket => School.vault.folder
end
