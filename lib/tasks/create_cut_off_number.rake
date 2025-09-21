# Create or update the cut off number value

task :create_cut_off_number => :environment do

  setting = Setting.where(["target_type ='school' and name ='cut_off_number' "]).first
  setting = Setting.create({:target_id => 1, :target_type => "school", :name => "cut_off_number", :value => 20}) unless setting

end
