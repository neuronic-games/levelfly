task :change_default_large_avatar_image => :environment do

  all_profiles = Profile.where(:image_file_name => "/images/wardrobe/null_profile.png")
  all_profiles.each do |profile|
    avatar = profile.avatar
    avatar.update_attributes(:face => 'avatar/face/latin_female', :hair => nil, :hair_back => nil) if avatar
  end
end