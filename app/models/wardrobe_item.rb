class WardrobeItem < ActiveRecord::Base
  belongs_to :wardrobe
  belongs_to :parent_item, :class_name => "WardrobeItem"
end
