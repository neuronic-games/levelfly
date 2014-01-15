task :create_wardrobe_accessories => :environment do
  wi = WardrobeItem.find_by_name("Jewlery")
  wi.name = "Jewelry"
  wi.save

  Wardrobe.add("Urban Cool", "Accessories", "Jewelry", "Nosestud", "earrings", "basic/earrings/nose_stud")
  Wardrobe.add("Urban Cool", "Accessories", "Gadgets", "Headphones", "prop", "basic/props/headphone")
  Wardrobe.add("Urban Cool", "Accessories", "Bags", "Messenger Bag", "prop", "basic/props/side_bag")
  Wardrobe.add("Urban Cool", "Head", "Hats", "Black Cap", "hat", "basic/hats/hat_red_black")
  Wardrobe.unlock("Urban Cool", 500)
  Reward.destroy_all(:target_type => 'wardrobe', :target_id => '2') # Sports
    
  Wardrobe.add("Purple Power Superhero", "Body", "Misc", "Purple Power", "top", "basic/tops/superhero_top")
  Wardrobe.add("Purple Power Superhero", "Legs", "Misc", "Purple Power", "bottom", "basic/bottoms/superhero_bottom")
  Wardrobe.add("Purple Power Superhero", "Feet", "Misc", "Purple Power", "shoes", "basic/shoes/superhero_boot")
  Wardrobe.unlock("Purple Power Superhero", 1000)
  Reward.destroy_all(:target_type => 'wardrobe', :target_id => '4') # Devil
  
  wi = WardrobeItem.find_by_name("Orange Necklace")
  wi.image_file = "basic/necklace/necklace_orange"
  wi.save

  wi = WardrobeItem.find_by_name("Orange Earrings")
  wi.image_file = "basic/earrings/earring_orange"
  wi.save
  
end

# Create a new Urban wardrobe and add Accessories > Jewlery > Nosestud
# Wardrobe.add("Urban", "Accessories", "Jewlery", "Nosestud", "earrings", "basic/earrings/nose_stud")

# Unlock the Urban wardrobe at 500 XP
# Wardrobe.unlock("Urban", 500)

# [Item Types]
# shoes
# bottom
# necklace
# top
# earrings
# glasses
# hat
# prop
# facial_hair
# facial_marks
