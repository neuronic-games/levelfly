class Group < ActiveRecord::Base
  belongs_to :school
  has_many :participants, as: :target
  has_many :messages, as: :parent

  has_attached_file :image,
                    storage: :s3,
                    s3_credentials: { access_key_id: ENV.fetch('S3_KEY', nil),
                                      secret_access_key: ENV.fetch('S3_SECRET', nil) },
                    path: 'schools/:school/courses/:course/group/:id/:filename',
                    bucket: ENV.fetch('S3_PATH', nil),
                    s3_protocol: ENV.fetch('S3_PROTOCOL', nil)
end
