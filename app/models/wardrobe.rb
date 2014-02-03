class Wardrobe < ActiveRecord::Base
  has_many :wardrobe_items

  def self.add(wardrobe_name, level_0_name, level_1_name, name, item_type, image_file, new_name=nil)
    wardrobe = Wardrobe.find(:first, :conditions => ["name like ?", wardrobe_name])
    if wardrobe.nil?
      wardrobe = Wardrobe.create(:name => wardrobe_name, :visible_level => 1, :available_level => 1, :available_date => Date.today, :visible_date => Date.today)
      puts "Wardrobe #{wardrobe.name} (#{wardrobe.id}) created"
    end
    
    level_0 = WardrobeItem.find(:first, :conditions => ["name like ? and parent_item_id is null and depth = 0", level_0_name])
    level_1 = WardrobeItem.find(:first, :conditions => ["name like ? and parent_item_id = ? and depth = 1", level_1_name, level_0.id])
    exists = WardrobeItem.find(:first, :conditions => ["name like ? and parent_item_id = ? and depth = 2", name, level_1.id])
    
    if exists
      exists.name = new_name if new_name
      exists.parent_item = level_1
      exists.save
      puts "#{exists.name} (#{exists.id}) updated"
    elseif new_name.nil?
      sort_order = WardrobeItem.maximum(:sort_order, :conditions => ["parent_item_id = ? and depth = 1", level_0.id])
      item = WardrobeItem.create(:wardrobe => wardrobe, :parent_item => level_1, :name => name, :item_type => item_type, :image_file => image_file, :sort_order => sort_order+1, :depth => 2)
      puts "#{item.name} (#{item.id}) added to #{level_1.name} (#{level_1.id}), #{level_0.name} (#{level_0.id}), #{wardrobe.name} (#{wardrobe.id})"
    end
    return
  end
  
  def self.unlock(wardrobe_name, xp)
    wardrobe = Wardrobe.find(:first, :conditions => ["name like ?", wardrobe_name])
    if wardrobe.nil?
      wardrobe = Wardrobe.create(:name => wardrobe_name, :visible_level => 1, :available_level => 1, :available_date => Date.today, :visible_date => Date.today)
      puts "Wardrobe #{wardrobe.name} (#{wardrobe.id}) created"
    end

    exists = Reward.find(:first, :conditions => {:target_type => 'wardrobe', :target_id => wardrobe.id})
    if exists
      exists.xp = xp
      exists.save
    else
      exists = Reward.create(:xp => xp, :target_type => 'wardrobe', :target_id => wardrobe.id)
    end
    
    puts "Wardrobe #{wardrobe.name} (#{wardrobe.id}) unlocked at #{xp} XP"
  end

  def self.unlock_lvl(wardrobe_name, lvl)
    wardrobe = Wardrobe.find(:first, :conditions => ["name like ?", wardrobe_name])
    if wardrobe.nil?
      wardrobe = Wardrobe.create(:name => wardrobe_name, :visible_level => 1, :available_level => 1, :available_date => Date.today, :visible_date => Date.today)
      puts "Wardrobe #{wardrobe.name} (#{wardrobe.id}) created"
    end

    lvl_reward = Reward.find(:first, :conditions => {:target_type => 'level', :target_id => lvl})
    return unless lvl_reward

    exists = Reward.find(:first, :conditions => {:target_type => 'wardrobe', :target_id => wardrobe.id})
    if exists
      exists.xp = lvl_reward.xp
      exists.save
    else
      exists = Reward.create(:xp => lvl_reward.xp, :target_type => 'wardrobe', :target_id => wardrobe.id)
    end
    
    puts "Wardrobe #{wardrobe.name} (#{wardrobe.id}) unlocked at level #{lvl_reward.target_id} and #{lvl_reward.xp} XP"
  end

end
