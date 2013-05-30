# Update gold medal icon for each outcome

task :update_gold_medal_icon => :environment do
  outcomes = Outcome.all
  updated_image_id = Badge.gold_badge_image
  outcomes.each do |outcome|
    badge = Badge.find_by_name("Gold Medal in #{outcome.name}")
    badge.update_attribute(:badge_image_id, updated_image_id) if badge
  end
end