class Group < ActiveRecord::Base
  belongs_to :school
  has_many :participants, as: :target
  has_many :messages, as: :parent

  has_one_attached :image
end
