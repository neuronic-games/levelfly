# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)

# School setting
school = School.create(:name => 'Burough of Manhattan Community College', :code => 'BMCC')
vault = Vault.create(:vault_type => 'AWS S3', :object_id => school.id, :object_type => 'School', :account => 'AKIAJMV6IAIXZQJJ2GHQ', :secret => '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', :folder => 'com.neuronicgames.oncampus.test/test')

profile = Profile.create(:code => 'DEFAULT', :school => school)
default = Avatar.create(:profile => profile, :level => 1, :skin => 3, :body => 'avatar/body/body_3', :head => 'avatar/head/diamond_3', :face => 'avatar/face/latin_male', :hair => 'avatar/hair/short_wavy_5', :hair_back => 'avatar/hair/short_wavy_5_back', :top => 'basic/tops/polo_short_sleeve_blue', :bottom => 'basic/bottoms/trousers_long_brown', :shoes => 'basic/shoes/sneakers_gray')

basic = Wardrobe.create(:name => 'Basic', :visible_level => 1, :available_level => 1, :available_date => Date.today, :visible_date => Date.today)

item_type_list = WardrobeItemType.create([{:name => 'head'}, {:name => 'body'}, {:name => 'legs'}, {:name => 'feet'}, {:name => 'prop'}, {:name => 'head_shape'}, {:name => 'face'}, {:name => 'hair'}, {:name => 'facial_hair'}, {:name => 'hat'}, {:name => 'top'}])
item_type = {}
item_type_list.each do |i|
  item_type[i.name] = i
end

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

# Body
item['body'] = WardrobeItem.create(:wardrobe => basic, :name => 'Body', :item_type => 'body', :sort_order => 1, :depth => 0)
item['body_casual'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['body'], :name => 'Casual', :item_type => 'casual', :sort_order => 0, :depth => 1)
item['body_dressy'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['body'], :name => 'Dressy', :item_type => 'dressy', :sort_order => 1, :depth => 1)
item['body_sporty'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['body'], :name => 'Sporty', :item_type => 'sporty', :sort_order => 2, :depth => 1)
item['body_career'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['body'], :name => 'Career', :item_type => 'career', :sort_order => 3, :depth => 1)
item['body_misc'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['body'], :name => 'Misc', :item_type => 'misc', :sort_order => 4, :depth => 1)

# Casual Tops
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_casual'], :name => 'Black T', :item_type => 'top', :image_file => 'basic/tops/black_t', :sort_order => 0, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_casual'], :name => 'Blue Polo', :item_type => 'top', :image_file => 'basic/tops/polo_short_sleeve_blue', :sort_order => 1, :depth => 2)
WardrobeItem.create(:wardrobe => basic, :parent_item => item['body_career'], :name => 'Lab Coat', :item_type => 'top', :image_file => 'basic/tops/doctor_white_top', :sort_order => 0, :depth => 2)

item['legs'] = WardrobeItem.create(:wardrobe => basic, :name => 'Legs', :item_type => 'legs', :sort_order => 2, :depth => 0)

item['feet'] = WardrobeItem.create(:wardrobe => basic, :name => 'Feet', :item_type => 'feet', :sort_order => 3, :depth => 0)

item['props'] = WardrobeItem.create(:wardrobe => basic, :name => 'Props', :item_type => 'prop', :sort_order => 4, :depth => 0)
