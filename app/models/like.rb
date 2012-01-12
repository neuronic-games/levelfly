class Like < ActiveRecord::Base
  belongs_to :message
  belongs_to :profile
end
