class WardrobeItem < ActiveRecord::Base
  belongs_to :wardrobe
  belongs_to :parent_item, :class_name => "WardrobeItem"
  
  def self.add(wardrobe_name, level_0_name, level_1_name, name, item_type, image_file)
    wardrobe = Wardrobe.find_by_name(wardrobe_name)
    if wardrobe.nil?
      wardrobe = Wardrobe.create(:name => wardrobe_name, :visible_level => 1, :available_level => 1, :available_date => Date.today, :visible_date => Date.today)
      puts "Wardrobe #{wardrobe.name} (#{wardrobe.id}) created"
    end
    
    level_0 = WardrobeItem.find(:first, :conditions => ["name = ? and parent_item_id is null and depth = 0", level_0_name])
    level_1 = WardrobeItem.find(:first, :conditions => ["name = ? and parent_item_id = ? and depth = 1", level_1_name, level_0.id])
    
    sort_order = WardrobeItem.maximum(:sort_order, :conditions => ["parent_item_id = ? and depth = 1", level_0.id])
    
    item = WardrobeItem.create(:wardrobe => wardrobe, :parent_item => level_1, :name => name, :item_type => item_type, :image_file => image_file, :sort_order => sort_order+1, :depth => 2)
    
    puts "#{item.name} (#{item.id}) added to #{level_1.name} (#{level_1.id}), #{level_0.name} (#{level_0.id}), #{wardrobe.name} (#{wardrobe.id})"
    return
  end
end
