class Course < ActiveRecord::Base
  belongs_to :school
  has_many :participants, :as => :object
  has_many :messages, :as => :parent
  has_many :categories
  has_many :outcomes
  has_many :attachments, :as => :object
  has_attached_file :image,
    :storage => :s3,
    :s3_credentials => { :access_key_id => 'AKIAJMV6IAIXZQJJ2GHQ', :secret_access_key => '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' },
    :path => "courses/:filename",
    :bucket => 'com.neuronicgames.oncampus.test/test'
end
