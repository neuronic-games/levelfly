class MessageViewer < ActiveRecord::Base
  belongs_to :message
  belongs_to :poster_profile, :class_name => "Profile"
  belongs_to :viewer_profile, :class_name => "Profile"
end
