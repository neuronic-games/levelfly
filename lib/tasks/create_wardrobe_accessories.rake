task :create_wardrobe_accessories => :environment do
  # Unlockable Pirate wardrobe
  wardrobe = Wardrobe.create(:name => 'Pirate', :visible_level => 1, :available_level => 1, :available_date => Date.today, :visible_date => Date.today)
  WardrobeItem.create(:wardrobe => wardrobe, :parent_item => item['hat'], :name => 'Pirate', :item_type => 'hat', :image_file => 'basic/hats/pirate_hat', :sort_order => 0, :depth => 2)
  WardrobeItem.create(:wardrobe => wardrobe, :parent_item => item['body_sporty'], :name => 'Basketball', :item_type => 'top', :image_file => 'sports/tops/basketball_t_shirt', :sort_order => 1, :depth => 2)
  WardrobeItem.create(:wardrobe => wardrobe, :parent_item => item['legs_sporty'], :name => 'Basketball', :item_type => 'bottom', :image_file => 'sports/bottoms/basketball_short', :sort_order => 4, :depth => 2)
  WardrobeItem.create(:wardrobe => wardrobe, :parent_item => item['legs_sporty'], :name => 'Hiking', :item_type => 'bottom', :image_file => 'sports/bottoms/hiking_short', :sort_order => 4, :depth => 2)
  WardrobeItem.create(:wardrobe => wardrobe, :parent_item => item['feet_sporty'], :name => 'Basketball', :item_type => 'shoes', :image_file => 'sports/shoes/basketball_shoe', :sort_order => 1, :depth => 2)
end

# shoes
# feet_casual
# feet_dressy
# feet_sporty
# feet_career
# feet_misc

# props
# props_jewelery
# props_bags
# props_gadgets
# props_hobbies
# props_misc
