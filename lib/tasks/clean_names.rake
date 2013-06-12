# Replace the student names
FIRST = ['Bruce', 'Peter', 'Clark', 'John', 'Sam', 'Tam', 'Joe', 'Frank', 'Susan', 'Jennifer', 'Sarah', 'Rebecca']
LAST = ['Wayne', 'Parker', 'Kent', 'Lane', 'Wise', 'Smith', 'Doe', 'Jacobs', 'Bloom', 'Walker']

task :clean_names => :environment do
  profiles = Profile.all
  profiles.each do |profile|
    profile.full_name = FIRST.sample + ' ' + LAST.sample
    profile.save
    puts profile.full_name
  end
end