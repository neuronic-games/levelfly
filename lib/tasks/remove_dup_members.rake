# Remove duplicate task members that were created due to an invite bug

task :remove_dup_members => :environment do
  list = TaskParticipant.all
  
  count = 0
  list.each do |tp|
    dup = TaskParticipant.find(:first, :conditions => ["task_id = ? and profile_id = ?", tp.task_id, tp.profile_id])
    if dup.complete_date.nil?
      puts "Removing task_participants ##{dup.id}"
      # We only want to delete this if this is not complete
      dup.destroy
      count += 1
    end
  end
  
  puts "#{count} duplicates removed"
end