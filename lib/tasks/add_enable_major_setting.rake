task :add_enable_major_setting => :environment do

  School.find_each do |school|
    Setting.find_or_create_by_object_id_and_object_type_and_name(:object_id => school.id, :object_type => "school", :name => "enable_majors", :value => "true")
  end
end