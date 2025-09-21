class Wardrobe < ActiveRecord::Base
  has_many :wardrobe_items

  def self.add(wardrobe_name, level_0_name, level_1_name, name, item_type, image_file, sort_order=nil, new_name=nil)
    wardrobe = Wardrobe.where(["name like ?", wardrobe_name]).first
    if wardrobe.nil?
      wardrobe = Wardrobe.create(:name => wardrobe_name, :visible_level => 1, :available_level => 1, :available_date => Date.today, :visible_date => Date.today)
      puts "Wardrobe #{wardrobe.name} (#{wardrobe.id}) created"
    end
    
    level_0 = WardrobeItem.where(["name like ? and parent_item_id is null and depth = 0", level_0_name]).first
    if level_0.nil?
      puts "ERROR: #{level_0_name} does not exit"
      return
    end
    level_1 = WardrobeItem.where(["name like ? and parent_item_id = ? and depth = 1", level_1_name, level_0.id]).first
    if level_1.nil?
      puts "ERROR: #{level_1_name} in #{level_0_name} does not exit"
      return
    end
    exists = WardrobeItem.where(["name like ? and parent_item_id = ? and depth = 2", name, level_1.id]).first
    
    if exists
      exists.name = new_name if new_name
      exists.parent_item = level_1
      exists.sort_order = sort_order unless sort_order.nil?
      exists.save
      puts "#{exists.name} (#{exists.id}) updated"
    else
      sort_order = WardrobeItem.maximum(:sort_order, :conditions => ["parent_item_id = ? and depth = 1", level_0.id]) + 1 if sort_order.nil?
      item = WardrobeItem.create(:wardrobe => wardrobe, :parent_item => level_1, :name => new_name ? new_name : name, :item_type => item_type, :image_file => image_file, :sort_order => sort_order, :depth => 2)
      puts "#{item.name} (#{item.id}) added to #{level_1.name} (#{level_1.id}), #{level_0.name} (#{level_0.id}), #{wardrobe.name} (#{wardrobe.id})"
    end
    return
  end
  
  def self.unlock(wardrobe_name, xp)
    wardrobe = Wardrobe.where(["name like ?", wardrobe_name]).first
    if wardrobe.nil?
      wardrobe = Wardrobe.create(:name => wardrobe_name, :visible_level => 1, :available_level => 1, :available_date => Date.today, :visible_date => Date.today)
      puts "Wardrobe #{wardrobe.name} (#{wardrobe.id}) created"
    end

    exists = Reward.where({:target_type => 'wardrobe', :target_id => wardrobe.id}).first
    if exists
      exists.xp = xp
      exists.save
    else
      exists = Reward.create(:xp => xp, :target_type => 'wardrobe', :target_id => wardrobe.id)
    end
    
    puts "Wardrobe #{wardrobe.name} (#{wardrobe.id}) unlocked at #{xp} XP"
  end

  def self.unlock_lvl(wardrobe_name, lvl)
    wardrobe = Wardrobe.where(["name like ?", wardrobe_name]).first
    if wardrobe.nil?
      wardrobe = Wardrobe.create(:name => wardrobe_name, :visible_level => 1, :available_level => 1, :available_date => Date.today, :visible_date => Date.today)
      puts "Wardrobe #{wardrobe.name} (#{wardrobe.id}) created"
    end

    lvl_reward = Reward.where({:target_type => 'level', :target_id => lvl}).first
    return unless lvl_reward

    exists = Reward.where({:target_type => 'wardrobe', :target_id => wardrobe.id}).first
    if exists
      exists.xp = lvl_reward.xp
      exists.save
    else
      exists = Reward.create(:xp => lvl_reward.xp, :target_type => 'wardrobe', :target_id => wardrobe.id)
    end
    
    puts "Wardrobe #{wardrobe.name} (#{wardrobe.id}) unlocked at level #{lvl_reward.target_id} and #{lvl_reward.xp} XP"
  end

end
