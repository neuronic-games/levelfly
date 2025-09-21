task :cleanup_wardrobe_mistakes => :environment do
  w = Wardrobe.find_by_name("Purple Power")
  if w
    w.name = "Purple Power Superhero"
    w.save
  end
  
  wi_list = WardrobeItem.where({:name => "Purple Man"})
  wi_list.each do |wi|
    wi.name = "Purple Power"
    wi.save
  end
  
  wi = WardrobeItem.where({:name => "Superhero", :item_type => "shoes"}).first
  wi.destroy if wi
end
