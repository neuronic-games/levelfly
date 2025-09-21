task create_gold_badge: :environment do
  badge = Badge.find_by_name('Gold Outcome')
  unless badge
    Badge.create(name: 'Gold Outcome',
                 descr: '"Gold Outcome" badge for each gold outcome that each student receive.', school_id: '1', badge_image_id: '42')
  end
end
