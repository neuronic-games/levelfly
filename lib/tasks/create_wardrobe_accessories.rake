task :create_wardrobe_accessories => :environment do
  wi = WardrobeItem.find_by_name("Jewlery")
  wi.name = "Jewelry"
  wi.save

  Wardrobe.add("Accessories 1", "Accessories", "Jewelry", "Nosestud", "earrings", "basic/earrings/nose_stud")
  Wardrobe.add("Accessories 1", "Accessories", "Gadgets", "Headphones", "prop", "basic/props/headphone")
  Wardrobe.add("Accessories 1", "Accessories", "Misc", "Teddy", "prop", "basic/props/pink_teddy")
  Wardrobe.add("Accessories 1", "Accessories", "Hobbies", "Folk Guitar", "prop", "basic/props/guitar_brown")
  Wardrobe.add("Accessories 1", "Accessories", "Jewelry", "Silver Necklace", "necklace", "basic/necklace/necklace_silver")
  Wardrobe.add("Accessories 1", "Accessories", "Bags", "Brown Handbag", "prop", "basic/props/hand_bag")
  Wardrobe.add("Accessories 1", "Accessories", "Bags", "Messenger Bag", "prop", "basic/props/side_bag")
  Wardrobe.add("Accessories 1", "Head", "Hats", "Black Cap", "hat", "basic/hats/hat_red_black")
  Wardrobe.unlock("Accessories 1", 500)
  Reward.destroy_all(:object_type => 'wardrobe', object_id => 3)  
  
  Wardrobe.add("Purple Man", "Body", "Misc", "Purple Man", "top", "basic/tops/superhero_top")
  Wardrobe.add("Purple Man", "Legs", "Misc", "Purple Man", "bottom", "basic/bottoms/superhero_bottom")
  Wardrobe.add("Purple Man", "Feet", "Misc", "Purple Man", "shoes", "basic/shoes/superhero_boot")
  Wardrobe.unlock("Purple Man", 1000)
  Reward.destroy_all(:object_type => 'wardrobe', object_id => 4)  
  
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
