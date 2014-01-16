task :add_enable_major_setting => :environment do

  School.find_each do |school|
    Setting.find_or_create_by_target_id_and_target_type_and_name(:target_id => school.id, :target_type => "school", :name => "enable_majors", :value => "true")
  end
end