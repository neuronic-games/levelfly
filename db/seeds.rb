# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)

# School setting
school = School.create(:name => 'Borough of Manhattan Community College', :code => 'BMCC', :handle => 'bmcc')
vault = Vault.create(:vault_type => 'AWS S3', :object_id => school.id, :object_type => 'School', :account => ENV['S3_KEY'], :secret => ENV['S3_SECRET'], :folder => ENV['S3_PATH'])

profile = Profile.create(:code => 'DEFAULT', :school => school, :image_file_name => Profile.default_avatar_image, :level => 1)
default = Avatar.create(:profile => profile, :skin => 3, :body => 'avatar/body/body_3', :head => 'avatar/head/diamond_3', :face => 'avatar/face/latin_male', :hair => 'avatar/hair/short_wavy_5', :hair_back => 'avatar/hair/short_wavy_5_back', :top => 'basic/tops/polo_short_sleeve_blue', :bottom => 'basic/bottoms/trousers_long_brown', :shoes => 'basic/shoes/sneakers_gray')

# admin = User.create(:email => 'admin@neuronicgames.com', :encrypted_password => '$2a$10$RvALTroqUHXm4oE2ID8O5OU/napTft9S6EzCWaAww7G6nIkZPe1Au')
# Profile.create(:user => admin, :school => school, :image_file_name => Profile.default_avatar_image, :level => 1, :full_name => "Admin")

admin = User.create(:email => "admin@neuronicgames.com", :encrypted_password => "$2a$10$r6oanIl6wuvMUDoyMeF7NeMfMQBkAPSLMEYseOm0mmiz...", :status => 'A')
admin_profile = Profile.create(:user => admin, :school => school, :full_name => "Neuronic Admin", :image_file_name => Profile.default_avatar_image)
Role.create(:name => "edit_user", :profile => admin_profile)
Role.create(:name => "modify_rewards", :profile => admin_profile)
Role.create(:name => "modify_wardrobe", :profile => admin_profile)
Role.create(:name => "modify_settings", :profile => admin_profile)

basic = Wardrobe.create(:name => 'Basic', :visible_level => 1, :available_level => 1, :available_date => Date.today, :visible_date => Date.today)

# item_type_list = WardrobeItemType.create([{:name => 'head'}, {:name => 'body'}, {:name => 'legs'}, {:name => 'feet'}, {:name => 'prop'}, {:name => 'head_shape'}, {:name => 'face'}, {:name => 'hair'}, {:name => 'facial_hair'}, {:name => 'hat'}, {:name => 'top'}])
# item_type = {}
# item_type_list.each do |i|
#   item_type[i.name] = i
# end

item = {}
# Head
item['head'] = WardrobeItem.create(:wardrobe => basic, :name => 'Head', :item_type => 'head', :sort_order => 0, :depth => 0)
item['head_shape'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['head'], :name => 'Shape', :item_type => 'head_shape', :sort_order => 0, :depth => 1)
item['face'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['head'], :name => 'Face', :item_type => 'face', :sort_order => 1, :depth => 1)
item['hair'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['head'], :name => 'Hair', :item_type => 'hair', :sort_order => 2, :depth => 1)
item['facial_hair'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['head'], :name => 'Facial Hair', :item_type => 'facial_hair', :sort_order => 3, :depth => 1)
item['hat'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['head'], :name => 'Hats', :item_type => 'hat', :sort_order => 4, :depth => 1)

# Head Shape
WardrobeItem.create(:wardrobe => basic, :parent_item => item['head_shape'], :name => 'Square', :item_type => 'head', :image_file => 'avatar/head/square_3', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['head_shape'], :name => 'Round', :item_type => 'head', :image_file => 'avatar/head/round_3', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['head_shape'], :name => 'Oval', :item_type => 'head', :image_file => 'avatar/head/oval_3', :sort_order => 2, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['head_shape'], :name => 'Diamond', :item_type => 'head', :image_file => 'avatar/head/diamond_3', :sort_order => 3, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['head_shape'], :name => 'Heart', :item_type => 'head', :image_file => 'avatar/head/heart_3', :sort_order => 4, :depth => 2)

# Face
WardrobeItem.create(:wardrobe => basic, :parent_item => item['face'], :name => 'Face 1', :item_type => 'face', :image_file => 'avatar/face/asian_male', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['face'], :name => 'Face 2', :item_type => 'face', :image_file => 'avatar/face/asian_female', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['face'], :name => 'Face 3', :item_type => 'face', :image_file => 'avatar/face/chinese_male', :sort_order => 3, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['face'], :name => 'Face 4', :item_type => 'face', :image_file => 'avatar/face/chinese_female', :sort_order => 4, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['face'], :name => 'Face 5', :item_type => 'face', :image_file => 'avatar/face/african_male', :sort_order => 5, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['face'], :name => 'Face 6', :item_type => 'face', :image_file => 'avatar/face/african_female', :sort_order => 6, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['face'], :name => 'Face 7', :item_type => 'face', :image_file => 'avatar/face/latin_male', :sort_order => 7, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['face'], :name => 'Face 8', :item_type => 'face', :image_file => 'avatar/face/latin_female', :sort_order => 8, :depth => 2)

# Hair
WardrobeItem.create(:wardrobe => basic, :parent_item => item['hair'], :name => 'Short Wavy', :item_type => 'hair', :image_file => 'avatar/hair/short_wavy_4', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['hair'], :name => 'Short Sraight', :item_type => 'hair', :image_file => 'avatar/hair/short_straight_4', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['hair'], :name => 'Short Side', :item_type => 'hair', :image_file => 'avatar/hair/short_side_4', :sort_order => 2, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['hair'], :name => 'Short Curly', :item_type => 'hair', :image_file => 'avatar/hair/short_curly_4', :sort_order => 3, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['hair'], :name => 'Long Wavy', :item_type => 'hair', :image_file => 'avatar/hair/long_wavy_4', :sort_order => 4, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['hair'], :name => 'Long Straight', :item_type => 'hair', :image_file => 'avatar/hair/long_straight_4', :sort_order => 5, :depth => 2)

# Facial Hair
WardrobeItem.create(:wardrobe => basic, :parent_item => item['facial_hair'], :name => 'Handlebar', :item_type => 'facial_hair', :image_file => 'avatar/facial_hair/handlebar_chin_puff_4', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['facial_hair'], :name => 'Souvarov', :item_type => 'facial_hair', :image_file => 'avatar/facial_hair/la_souvarov_4', :sort_order => 1, :depth => 2)

# Hat
WardrobeItem.create(:wardrobe => basic, :parent_item => item['hat'], :name => 'Cowboy', :item_type => 'hat', :image_file => 'basic/hats/cowboy_hat', :sort_order => 0, :depth => 2)

# Body
item['body'] = WardrobeItem.create(:wardrobe => basic, :name => 'Body', :item_type => 'body', :sort_order => 1, :depth => 0)
item['body_casual'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['body'], :name => 'Casual', :item_type => 'casual', :sort_order => 0, :depth => 1)
item['body_dressy'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['body'], :name => 'Dressy', :item_type => 'dressy', :sort_order => 1, :depth => 1)
item['body_sporty'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['body'], :name => 'Sporty', :item_type => 'sporty', :sort_order => 2, :depth => 1)
item['body_career'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['body'], :name => 'Career', :item_type => 'career', :sort_order => 3, :depth => 1)
item['body_misc'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['body'], :name => 'Misc', :item_type => 'misc', :sort_order => 4, :depth => 1)

# Casual Tops
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_casual'], :name => 'Black-T', :item_type => 'top', :image_file => 'basic/tops/black_t', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_casual'], :name => 'Blue Polo', :item_type => 'top', :image_file => 'basic/tops/polo_short_sleeve_blue', :sort_order => 1, :depth => 2)

# Dressy Tops
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_dressy'], :name => 'Black Tux', :item_type => 'top', :image_file => 'basic/tops_dressy/black_bow', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_dressy'], :name => 'Black Suit', :item_type => 'top', :image_file => 'basic/tops_dressy/dark_gray_tie', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_dressy'], :name => 'Black Dress', :item_type => 'top', :image_file => 'basic/tops_dressy/black_maroon_short_dress', :sort_order => 2, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_dressy'], :name => 'White Dress', :item_type => 'top', :image_file => 'basic/tops_dressy/black_white_long_dress', :sort_order => 3, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_dressy'], :name => 'Brown Dress', :item_type => 'top', :image_file => 'basic/tops_dressy/brown_dress', :sort_order => 4, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_dressy'], :name => 'Orange Dress', :item_type => 'top', :image_file => 'basic/tops_dressy/orange_short_dress', :sort_order => 5, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_dressy'], :name => 'Red Dress', :item_type => 'top', :image_file => 'basic/tops_dressy/red_long_dress', :sort_order => 6, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_dressy'], :name => 'White Dress 2', :item_type => 'top', :image_file => 'basic/tops_dressy/white_dress_1', :sort_order => 7, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_dressy'], :name => 'White Dress 3', :item_type => 'top', :image_file => 'basic/tops_dressy/white_short_dress', :sort_order => 8, :depth => 2)

# Sporty Tops
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_sporty'], :name => 'Baseball', :item_type => 'top', :image_file => 'basic/tops/baseball_t_shirt', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_sporty'], :name => 'Football', :item_type => 'top', :image_file => 'basic/tops/american_football_top', :sort_order => 1, :depth => 2)

# Career Tops
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_career'], :name => 'Lab Coat', :item_type => 'top', :image_file => 'basic/tops/doctor_white_top', :sort_order => 0, :depth => 2)

# Misc Tops
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_misc'], :name => 'Santa', :item_type => 'top', :image_file => 'basic/tops/santa_top', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_misc'], :name => 'Cowboy', :item_type => 'top', :image_file => 'basic/tops/cowboy_top_with_court', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_misc'], :name => 'Pirate', :item_type => 'top', :image_file => 'basic/tops/pirate_top', :sort_order => 2, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_misc'], :name => 'Devil', :item_type => 'top', :image_file => 'basic/tops_misc/devil_short_dress', :sort_order => 2, :depth => 2)

item['legs'] = WardrobeItem.create(:wardrobe => basic, :name => 'Legs', :item_type => 'legs', :sort_order => 2, :depth => 0)
item['legs_casual'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs'], :name => 'Casual', :item_type => 'casual', :sort_order => 0, :depth => 1)
item['legs_dressy'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs'], :name => 'Dressy', :item_type => 'dressy', :sort_order => 1, :depth => 1)
item['legs_sporty'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs'], :name => 'Sporty', :item_type => 'sporty', :sort_order => 2, :depth => 1)
item['legs_career'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs'], :name => 'Career', :item_type => 'career', :sort_order => 3, :depth => 1)
item['legs_misc'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs'], :name => 'Misc', :item_type => 'misc', :sort_order => 4, :depth => 1)

# Casual Bottoms
WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs_casual'], :name => 'Short Denim', :item_type => 'bottom', :image_file => 'basic/bottoms/trousers_short_denim_blue', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs_casual'], :name => 'Long Denim', :item_type => 'bottom', :image_file => 'basic/bottoms/trousers_long_denim_blue', :sort_order => 1, :depth => 2)

# Dressy Bottoms
WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs_dressy'], :name => 'Grey Trousers', :item_type => 'bottom', :image_file => 'basic/bottoms/gray_brown_long_trouser', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs_dressy'], :name => 'Short Brown Skirt', :item_type => 'bottom', :image_file => 'basic/bottoms/skirt_short_brown', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs_dressy'], :name => 'Short Pink Skirt', :item_type => 'bottom', :image_file => 'basic/bottoms/skirt_short_pink', :sort_order => 2, :depth => 2)

# Sporty Bottoms
WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs_sporty'], :name => 'Football', :item_type => 'bottom', :image_file => 'basic/bottoms/american_football_pant', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs_sporty'], :name => 'Baseball', :item_type => 'bottom', :image_file => 'basic/bottoms/baseball_pant', :sort_order => 1, :depth => 2)

# Career Bottoms
WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs_career'], :name => 'Army', :item_type => 'bottom', :image_file => 'basic/bottoms/trouser_army', :sort_order => 0, :depth => 2)

# Misc Bottoms
WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs_misc'], :name => 'Santa', :item_type => 'bottom', :image_file => 'basic/bottoms/santa_trouser', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs_misc'], :name => 'Devil', :item_type => 'bottom', :image_file => 'basic/bottoms/trouser_devil', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['legs_misc'], :name => 'Pirate', :item_type => 'bottom', :image_file => 'basic/bottoms/pirate_bottom', :sort_order => 2, :depth => 2)

item['feet'] = WardrobeItem.create(:wardrobe => basic, :name => 'Feet', :item_type => 'feet', :sort_order => 3, :depth => 0)
item['feet_casual'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet'], :name => 'Casual', :item_type => 'casual', :sort_order => 0, :depth => 1)
item['feet_dressy'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet'], :name => 'Dressy', :item_type => 'dressy', :sort_order => 1, :depth => 1)
item['feet_sporty'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet'], :name => 'Sporty', :item_type => 'sporty', :sort_order => 2, :depth => 1)
item['feet_career'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet'], :name => 'Career', :item_type => 'career', :sort_order => 3, :depth => 1)
item['feet_misc'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet'], :name => 'Misc', :item_type => 'misc', :sort_order => 4, :depth => 1)

# Casual Shoes
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_casual'], :name => 'Brown Slippers', :item_type => 'shoes', :image_file => 'basic/shoes/slippers_brown', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_casual'], :name => 'Purple Slippers', :item_type => 'shoes', :image_file => 'basic/shoes/slippers_purple', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_casual'], :name => 'Grey Sneakers', :item_type => 'shoes', :image_file => 'basic/shoes/sneakers_gray', :sort_order => 2, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_casual'], :name => 'Purple Sneakers', :item_type => 'shoes', :image_file => 'basic/shoes/sports_shoe_purple', :sort_order => 2, :depth => 2)

# Dressy Shoes
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_dressy'], :name => 'Black', :item_type => 'shoes', :image_file => 'basic/shoes/black_shoe', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_dressy'], :name => 'Red Heels', :item_type => 'shoes', :image_file => 'basic/shoes/red_heels', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_dressy'], :name => 'Pink Heels', :item_type => 'shoes', :image_file => 'basic/shoes/shoe_pink', :sort_order => 2, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_dressy'], :name => 'White Heels', :item_type => 'shoes', :image_file => 'basic/shoes/white_heels_1', :sort_order => 3, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_dressy'], :name => 'White Heels 2', :item_type => 'shoes', :image_file => 'basic/shoes/white_heels_2', :sort_order => 4, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_dressy'], :name => 'Black Heels', :item_type => 'shoes', :image_file => 'basic/shoes/black_heels', :sort_order => 5, :depth => 2)

# Sporty Shoes
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_sporty'], :name => 'Football', :item_type => 'shoes', :image_file => 'basic/shoes/american_football_shoe', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_sporty'], :name => 'Baseball', :item_type => 'shoes', :image_file => 'basic/shoes/baseball_shoe', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_sporty'], :name => 'Golf', :item_type => 'shoes', :image_file => 'basic/shoes/golf_shoe', :sort_order => 2, :depth => 2)

# Career Shoes
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_career'], :name => 'Army', :item_type => 'shoes', :image_file => 'basic/shoes/army_boot', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_career'], :name => 'Cowboy', :item_type => 'shoes', :image_file => 'basic/shoes/cowboy_boot', :sort_order => 1, :depth => 2)

# Misc Shoes
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_misc'], :name => 'Superhero', :item_type => 'shoes', :image_file => 'basic/shoes/superhero_boot', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_misc'], :name => 'Pirate', :item_type => 'shoes', :image_file => 'basic/shoes/pirate_boot', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['feet_misc'], :name => 'Devil', :item_type => 'shoes', :image_file => 'basic/shoes/devil_boot', :sort_order => 2, :depth => 2)

item['props'] = WardrobeItem.create(:wardrobe => basic, :name => 'Accessories', :item_type => 'prop', :sort_order => 4, :depth => 0)
item['props_jewelery'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['props'], :name => 'Jewelery', :item_type => 'jewlery', :sort_order => 0, :depth => 1)
item['props_bags'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['props'], :name => 'Bags', :item_type => 'bag', :sort_order => 1, :depth => 1)
item['props_gadgets'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['props'], :name => 'Gadgets', :item_type => 'gadget', :sort_order => 2, :depth => 1)
item['props_hobbies'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['props'], :name => 'Hobbies', :item_type => 'hobby', :sort_order => 3, :depth => 1)
item['props_misc'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['props'], :name => 'Misc', :item_type => 'misc', :sort_order => 4, :depth => 1)

# Jewlery
WardrobeItem.create(:wardrobe => basic, :parent_item => item['props_jewelery'], :name => 'Orange Necklace', :item_type => 'necklace', :image_file => 'basic/earrings/necklace_orange', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['props_jewelery'], :name => 'Orange Earrings', :item_type => 'earrings', :image_file => 'basic/necklace/earring_orange', :sort_order => 1, :depth => 2)

# Bags
WardrobeItem.create(:wardrobe => basic, :parent_item => item['props_bags'], :name => 'Leather Bag', :item_type => 'prop', :image_file => 'basic/props/leather_bag', :sort_order => 0, :depth => 2)

# Gadgets
WardrobeItem.create(:wardrobe => basic, :parent_item => item['props_gadgets'], :name => 'Camera', :item_type => 'prop', :image_file => 'basic/props/camera', :sort_order => 0, :depth => 2)

# Hobbies
WardrobeItem.create(:wardrobe => basic, :parent_item => item['props_hobbies'], :name => 'Guitar', :item_type => 'prop', :image_file => 'basic/props/guitar_black', :sort_order => 0, :depth => 2)

# Misc
WardrobeItem.create(:wardrobe => basic, :parent_item => item['props_misc'], :name => 'Pitchfork', :item_type => 'prop', :image_file => 'basic/props/pitchfork', :sort_order => 0, :depth => 2)

# Unlockable Pirate wardrobe
pirate = Wardrobe.create(:name => 'Pirate', :visible_level => 1, :available_level => 1, :available_date => Date.today, :visible_date => Date.today)
WardrobeItem.create(:wardrobe => pirate, :parent_item => item['hat'], :name => 'Pirate', :item_type => 'hat', :image_file => 'basic/hats/pirate_hat', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => pirate, :parent_item => item['body_sporty'], :name => 'Basketball', :item_type => 'top', :image_file => 'sports/tops/basketball_t_shirt', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => pirate, :parent_item => item['body_sporty'], :name => 'Golf', :item_type => 'top', :image_file => 'sports/tops/golf_dress', :sort_order => 2, :depth => 2)
WardrobeItem.create(:wardrobe => pirate, :parent_item => item['body_sporty'], :name => 'Hiking', :item_type => 'top', :image_file => 'sports/tops/hiking_dress', :sort_order => 3, :depth => 2)
WardrobeItem.create(:wardrobe => pirate, :parent_item => item['body_sporty'], :name => 'Referee', :item_type => 'top', :image_file => 'sports/tops/Referee_t_shirt', :sort_order => 4, :depth => 2)
WardrobeItem.create(:wardrobe => pirate, :parent_item => item['legs_sporty'], :name => 'Basketball', :item_type => 'bottom', :image_file => 'sports/bottoms/basketball_short', :sort_order => 4, :depth => 2)
WardrobeItem.create(:wardrobe => pirate, :parent_item => item['legs_sporty'], :name => 'Hiking', :item_type => 'bottom', :image_file => 'sports/bottoms/hiking_short', :sort_order => 4, :depth => 2)
WardrobeItem.create(:wardrobe => pirate, :parent_item => item['feet_sporty'], :name => 'Basketball', :item_type => 'shoes', :image_file => 'sports/shoes/basketball_shoe', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => pirate, :parent_item => item['feet_sporty'], :name => 'Golf', :item_type => 'shoes', :image_file => 'sports/shoes/golf_shoe', :sort_order => 2, :depth => 2)
WardrobeItem.create(:wardrobe => pirate, :parent_item => item['feet_sporty'], :name => 'Hiking', :item_type => 'shoes', :image_file => 'sports/shoes/hiking_shoe', :sort_order => 3, :depth => 2)

# Unlockable Sports wardrobe
sports = Wardrobe.create(:name => 'Sports', :visible_level => 1, :available_level => 1, :available_date => Date.today, :visible_date => Date.today)
WardrobeItem.create(:wardrobe => sports, :parent_item => item['body_sporty'], :name => 'Basketball', :item_type => 'top', :image_file => 'sports/tops/basketball_t_shirt', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => sports, :parent_item => item['body_sporty'], :name => 'Golf', :item_type => 'top', :image_file => 'sports/tops/golf_dress', :sort_order => 2, :depth => 2)
WardrobeItem.create(:wardrobe => sports, :parent_item => item['body_sporty'], :name => 'Hiking', :item_type => 'top', :image_file => 'sports/tops/hiking_dress', :sort_order => 3, :depth => 2)
WardrobeItem.create(:wardrobe => sports, :parent_item => item['body_sporty'], :name => 'Referee', :item_type => 'top', :image_file => 'sports/tops/Referee_t_shirt', :sort_order => 4, :depth => 2)
WardrobeItem.create(:wardrobe => sports, :parent_item => item['legs_sporty'], :name => 'Basketball', :item_type => 'bottom', :image_file => 'sports/bottoms/basketball_short', :sort_order => 4, :depth => 2)
WardrobeItem.create(:wardrobe => sports, :parent_item => item['legs_sporty'], :name => 'Hiking', :item_type => 'bottom', :image_file => 'sports/bottoms/hiking_short', :sort_order => 4, :depth => 2)
WardrobeItem.create(:wardrobe => sports, :parent_item => item['feet_sporty'], :name => 'Basketball', :item_type => 'shoes', :image_file => 'sports/shoes/basketball_shoe', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => sports, :parent_item => item['feet_sporty'], :name => 'Golf', :item_type => 'shoes', :image_file => 'sports/shoes/golf_shoe', :sort_order => 2, :depth => 2)
WardrobeItem.create(:wardrobe => sports, :parent_item => item['feet_sporty'], :name => 'Hiking', :item_type => 'shoes', :image_file => 'sports/shoes/hiking_shoe', :sort_order => 3, :depth => 2)

# School Grades
GradeType.create(:school_id => school, :letter => 'A', :value_min => 93, :value => 95, :gpa=> 4.0)
GradeType.create(:school_id => school, :letter => 'A-', :value_min => 90, :value => 91.66, :gpa=> 3.7)
GradeType.create(:school_id => school, :letter => 'B+', :value_min => 87, :value => 88.33, :gpa=> 3.3)
GradeType.create(:school_id => school, :letter => 'B', :value_min => 83, :value => 85, :gpa=> 3.0)
GradeType.create(:school_id => school, :letter => 'B-', :value_min => 80, :value => 81.66, :gpa=> 2.7)
GradeType.create(:school_id => school, :letter => 'C+', :value_min => 77, :value => 78.33, :gpa=> 2.3)
GradeType.create(:school_id => school, :letter => 'C', :value_min => 73, :value => 75, :gpa=> 2.0)
GradeType.create(:school_id => school, :letter => 'C-', :value_min => 70, :value => 71.66, :gpa=> 1.7)
GradeType.create(:school_id => school, :letter => 'D+', :value_min => 67, :value => 68.33, :gpa=> 1.3)
GradeType.create(:school_id => school, :letter => 'D', :value_min => 63, :value => 65, :gpa=> 1.0)
GradeType.create(:school_id => school, :letter => 'D-', :value_min => 60, :value => 61.66, :gpa=> 0.7)
GradeType.create(:school_id => school, :letter => 'F', :value_min => 0, :value => 55, :gpa=> 0.0)
GradeType.create(:school_id => school, :letter => 'U', :value_min => 0, :value => 0, :gpa=> 0.0)

# Badge_images
BadgeImage.create(:image_file_name => '1st_prize.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => '1stprize2.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'alphabet.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'apple.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'award1.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'award2.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'bell.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'books.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'calculator.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'chamical.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'cheer_girl.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'clock.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'cup.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'cup3.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'cup4.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'cut.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'degree.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'desktop.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'divider.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'drive.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'edit.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'education.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'football_Cup.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'game_helmet.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'genetic_search.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'globe.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'globe2.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'graduate.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'idea.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'indore_sport.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'locker.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'maths.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'medal1.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'microscope.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'microscope2.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'music.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'notes.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'search.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'search_people.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'testtube.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'traphy6.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'traphy7.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'trophy1.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'trophy2.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'trophy3.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'trophy4.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'trophy5.png', :image_content_type =>"image/png")
BadgeImage.create(:image_file_name => 'university.png', :image_content_type =>"image/png")

#Gold_Outcome_Badge
Badge.create(:name => 'Gold Outcome', :descr => 'For Each Gold Outcome', :school_id => "1", :badge_image_id => "42")

#reward 
Reward.create(:xp => "0", :object_type => 'level', :object_id => "1")
Reward.create(:xp => "250", :object_type => 'level', :object_id => "2")
Reward.create(:xp => "500", :object_type => 'level', :object_id => "3")
Reward.create(:xp => "1000", :object_type => 'level', :object_id => "4")
Reward.create(:xp => "2000", :object_type => 'level', :object_id => "5")
Reward.create(:xp => "3000", :object_type => 'level', :object_id => "6")
Reward.create(:xp => "400", :object_type => 'wardrobe', :object_id => "2")

#majors
Major.create(:school_id => school, :name =>"Accounting", :code => "ACC")
Major.create(:school_id => school, :name =>"Bilingual Childhood Education", :code => "BCE")
Major.create(:school_id => school, :name =>"Biotechnology", :code => "BTC")
Major.create(:school_id => school, :name =>"Business Administration", :code => "BAM")
Major.create(:school_id => school, :name =>"Business Management", :code => "BMN")
Major.create(:school_id => school, :name =>"Child Care/Early Childhood Education", :code => "CCE")
Major.create(:school_id => school, :name =>"Childhood Education", :code => "CED")
Major.create(:school_id => school, :name =>"Computer Information Systems", :code => "CIS")
Major.create(:school_id => school, :name =>"Computer Network Technology", :code => "CNT")
Major.create(:school_id => school, :name =>"Computer Science", :code => "CSC")
Major.create(:school_id => school, :name =>"Criminal Justice", :code => "CRJ")
Major.create(:school_id => school, :name =>"Engineering Science", :code => "ENGS")
Major.create(:school_id => school, :name =>"Health Information Technology", :code => "HIT")
Major.create(:school_id => school, :name =>"Human Services", :code => "HSC")
Major.create(:school_id => school, :name =>"Liberal Arts", :code => "LAR")
Major.create(:school_id => school, :name =>"Mathematics", :code => "MTH")
Major.create(:school_id => school, :name =>"Multimedia Programming and Design", :code => "MPD")
Major.create(:school_id => school, :name =>"Nursing", :code => "NUR")
Major.create(:school_id => school, :name =>"Office Automation", :code => "OFA")
Major.create(:school_id => school, :name =>"Office Operations", :code => "OFO")
Major.create(:school_id => school, :name =>"Paramedic", :code => "PAR")
Major.create(:school_id => school, :name =>"Respiratory Therapy", :code => "RTH")
Major.create(:school_id => school, :name =>"Science", :code => "SCI")
Major.create(:school_id => school, :name =>"Science for Forensics", :code => "SCF")
Major.create(:school_id => school, :name =>"Small Business/Entrepreneurship", :code => "SBE")
Major.create(:school_id => school, :name =>"Theatre", :code => "THE")
Major.create(:school_id => school, :name =>"Video Arts and Technology", :code => "VAT")
Major.create(:school_id => school, :name =>"Writing and Literature", :code => "WLI")

