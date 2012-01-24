class Task < ActiveRecord::Base
  belongs_to :category
  belongs_to :school
  belongs_to :task
  belongs_to :course
  has_many :participants, :as => :object
  has_many :attachments, :as => :object
  has_many :messages, :as => :parent
  has_many :outcome_tasks
  has_attached_file :image,
    :storage => :s3,
    :s3_credentials => { :access_key_id => ENV['S3_KEY'], :secret_access_key => ENV['S3_SECR'] },
    :path => "resources/:filename",
    :bucket => ENV['S3_BUCK']
end
