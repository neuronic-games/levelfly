class App < ActiveRecord::Base
 belongs_to :school
 
 has_attached_file :image,
   :storage => :s3,
   :s3_credentials => { :access_key_id => ENV['S3_KEY'], :secret_access_key => ENV['S3_SECRET'] },
   :path => "schools/:school/apps/:id/:filename",
   :bucket => ENV['S3_PATH'],
   :s3_protocol => ENV['S3_PROTOCOL']
end
