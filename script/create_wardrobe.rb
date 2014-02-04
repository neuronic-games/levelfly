#!/usr/bin/env ruby

# Property of Levelfly. All rights reserved.
# Create wardrobe upload script from spreadsheet.
# https://docs.google.com/spreadsheet/ccc?key=0Aihj5DfFRufddGZvRkYzRlgtNUZFLVVRWVB6ZHpGOGc&usp=drive_web#gid=0
# Usage: create_wardrobe.rb IN=[csv file] OUT=[output script file] SOURCE=<source image root> TARGET=[target image root]
# Date: 2014-02-03 Tam

require "csv"
require "fileutils"
require "set"

source_path = nil
target_root = File.expand_path('../../public/images/wardrobe',  __FILE__)
file_path = File.expand_path('../wardrobe.csv',  __FILE__)
out_path = File.expand_path('../load_wardrobe.rb',  __FILE__)

ARGV.each do |argv|
  name, value = argv.split("=")
  file_path = value if name == 'IN'
  source_path = value if name == 'SOURCE'
  target_root = value if name == 'TARGET'
  out_path = value if name == 'OUT'
end

puts "Using wardrobe data from #{file_path}"
puts "Using wardrobe images in #{source_path}"
puts "Copying wardrobe images to #{target_root}"

reward_name = nil
item_names = Set.new
wardrobe_count = 0
item_count = 0
sort_order = {}

file = File.new(file_path, "r")
csv_data = file.read

out  = File.new(out_path, "w")
out.write "#!/usr/bin/env ruby\n\n"
out.write "# Property of Levelfly. All rights reserved. Date: #{Date.today}\n\n"

out.write "Reward.delete_all(\"target_type = 'wardrobe'\")\n"  # Remove existing wardrobe rewards because they will be re-added

csv_data.tr("\r", "\n").each_line do | line |
  next if line.match(/^\s*#/)

  data = CSV.parse_line(line)
  data.collect! { |x| x ? x.strip : x } 
  status, level, reward, wardrobe_top, wardrobe_sub, item_type, item_name, new_name, img_folder, img_file, icon_folder, icon_file = data

  # We assume that a data row will have a level unlock
  next if level.to_i == 0

  sort_order["#{wardrobe_top},#{wardrobe_sub}"] = 0 unless sort_order["#{wardrobe_top},#{wardrobe_sub}"]
  
  if reward and !reward.empty?
    if reward_name != reward
      # Update the unlock level at the end of the wardrobe item block
      out.write "\n# === #{reward} ===\n"
      out.write "Wardrobe.unlock_lvl('#{reward}', #{level})\n"
      wardrobe_count += 1
    end
    reward_name = reward
    reward_level = level
  end
  reward_folder = reward_name.downcase.strip.sub(/\s+/, '_')

  next if item_name.nil?  # Key field
  if item_names.include?(item_name)
    puts "ERROR: #{item_name} must be unique"
    next
  end
  
  item_name, item_seq = item_name.split(',')
  next if item_seq  # This script can't handle hair and facial_hair yet
  item_name.strip!
  
  next if item_type.nil?
  next if icon_file.nil?
  next if img_file.nil?
  extname = File.extname(img_file)
  basename = File.basename(img_file, extname)

  # Wardrobe image
  target_path = "#{target_root}/#{reward_folder}/#{img_folder}"
  FileUtils.mkdir_p(target_path)
  FileUtils.cp("#{source_path}/avatar/#{img_folder}/#{img_file}", target_path)

  # Wardrobe icon
  target_path = "#{target_root}/icon/#{reward_folder}/#{img_folder}" # folder should be the same as img_folder
  FileUtils.mkdir_p(target_path)
  FileUtils.cp("#{source_path}/icon/avatar/#{icon_folder}/#{icon_file}", "#{target_path}/#{basename}_icon#{extname}")

  out.write "Wardrobe.add('#{reward_name}', '#{wardrobe_top}', '#{wardrobe_sub}', '#{item_name}', '#{item_type}', '#{reward_folder}/#{img_folder}/#{basename}'"
  out.write ", "
  out.write sort_order["#{wardrobe_top},#{wardrobe_sub}"]
  out.write ", '#{new_name}'" if new_name
  out.write ")\n"
  
  item_count += 1
  sort_order["#{wardrobe_top},#{wardrobe_sub}"] += 1

  puts "#{reward_name}: #{new_name ? new_name : item_name} (#{img_file})"

end

puts "#{item_count} items in #{wardrobe_count} wardrobes"
puts "Output: #{out_path}"

file.close
out.close
