class BadgeImage < ActiveRecord::Base
has_attached_file :image,
    :styles => {
      :thumb=> "100x100#",
      :small  => "67x67>" }

end
