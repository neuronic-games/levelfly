class Group < ActiveRecord::Base
  belongs_to :school
  has_many :participants, as: :target
  has_many :messages, as: :parent

  has_attached_file :image,
                    path: 'schools/:school/courses/:course/group/:id/:filename'
  # FIXME: https://stackoverflow.com/a/21898204/14269772
  do_not_validate_attachment_file_type :image
end
