# Create or update the cut off number value

task :create_cut_off_number => :environment do

  setting = Setting.find(:first, :conditions=>["object_type ='school' and name ='cut_off_number' "])
  setting = Setting.create({:object_id => 1, :object_type => "school", :name => "cut_off_number", :value => 20}) unless setting

end