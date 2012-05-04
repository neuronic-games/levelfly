class Task < ActiveRecord::Base
  has_many :group
  belongs_to :category
  belongs_to :school
  belongs_to :task
  belongs_to :course
  belongs_to :group
  has_many :participants, :as => :object
  has_many :attachments, :as => :object
  has_many :messages, :as => :parent
  has_many :outcome_tasks
  has_attached_file :image,
    :storage => :s3,
    :s3_credentials => { :access_key_id => Vault.default_account, :secret_access_key => Vault.default_secret },
    :path => "schools/:school/courses/:course/tasks/:id/:filename",
    :bucket => Vault.default_folder
end
