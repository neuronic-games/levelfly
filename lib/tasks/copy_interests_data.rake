# Copy Interest Data Into the new text box

task copy_interests_data: :environment do
  profiles = Profile.all
  profiles.each do |profile|
    profile.update_attributes(interests: profile.tag_list.to_s)
  end
end
