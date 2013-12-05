class Group < ActiveRecord::Base
 belongs_to :school
 has_many :participants, :as => :object
 has_many :messages, :as => :parent
 
 has_attached_file :image,
   :storage => :s3,
   :s3_credentials => { :access_key_id => ENV['S3_KEY'], :secret_access_key => ENV['S3_SECRET'] },
   :path => "schools/:school/courses/:course/group/:id/:filename",
   :bucket => ENV['S3_PATH']
end
