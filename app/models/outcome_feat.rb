class OutcomeFeat < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :outcome
  belongs_to :feat
  belongs_to :profile
end
