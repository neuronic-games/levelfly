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

profile = Profile.create(:code => 'DEFAULT')
default = Avatar.create(:profile => profile, :level => 1, :skin => 3, :body => 'avatar/body/body_3', :head => 'avatar/head/diamond_3', :hair => 'avatar/hair/short_wavy_5', :hair_back => 'avatar/hair/short_wavy_5_back', :top => 'basic/tops/polo_short_sleeve_blue', :bottom => 'basic/bottoms/trousers_long_brown', :shoes => 'basic/shoes/sneakers_gray')

basic = Wardrobe.create(:name => 'Basic', :visible_level => 1, :available_level => 1, :available_date => Date.today, :visible_date => Date.today)

item_type_list = WardrobeItemType.create([{:name => 'head'}, {:name => 'body'}, {:name => 'legs'}, {:name => 'feet'}, {:name => 'props'}, {:name => 'head_shape'}, {:name => 'face'}, {:name => 'hair'}, {:name => 'facial_hair'}, {:name => 'hat'}])
item_type = {}
item_type_list.each do |i|
  item_type[i.name] = i
end

item = {}
item['head'] = WardrobeItem.create(:wardrobe => basic, :name => 'Head', :item_type => item_type['head'], :sort_order => 0, :depth => 0)
item['head_shape'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['head'], :name => 'Shape', :item_type => item_type['head_shape'], :sort_order => 0, :depth => 1)
item['face'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['head'], :name => 'Face', :item_type => item_type['face'], :sort_order => 1, :depth => 1)
item['hair'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['head'], :name => 'Hair', :item_type => item_type['hair'], :sort_order => 2, :depth => 1)
item['facial_hair'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['head'], :name => 'Facial Hair', :item_type => item_type['facial_hair'], :sort_order => 3, :depth => 1)
item['hat'] = WardrobeItem.create(:wardrobe => basic, :parent_item => item['head'], :name => 'Hats', :item_type => item_type['hat'], :sort_order => 4, :depth => 1)

item['body'] = WardrobeItem.create(:wardrobe => basic, :name => 'Body', :item_type => item_type['body'], :sort_order => 1, :depth => 0)

item['legs'] = WardrobeItem.create(:wardrobe => basic, :name => 'Legs', :item_type => item_type['legs'], :sort_order => 2, :depth => 0)

item['feet'] = WardrobeItem.create(:wardrobe => basic, :name => 'Feet', :item_type => item_type['feet'], :sort_order => 3, :depth => 0)

item['props'] = WardrobeItem.create(:wardrobe => basic, :name => 'Props', :item_type => item_type['props'], :sort_order => 4, :depth => 0)
