# Remove duplicate task members that were created due to an invite bug

task :remove_dup_members => :environment do
  list = TaskParticipant.all
  puts "Checking #{list.count} participants"
  count = 0
  list.each do |tp|
    dups = TaskParticipant.find(:all, :conditions => ["task_id = ? and profile_id = ? and id <> ?", tp.task_id, tp.profile_id, tp.id])
    dups.each do |dup|
      if dup and dup.complete_date.nil?
        puts "Removing task_participants ##{dup.id}: status=#{status} profile_type=#{profile_type} assign_date=#{assign_date} complete_date=#{complete_date} xp_award_date=#{xp_award_date}"
        # We only want to delete this if this is not complete
        # dup.destroy
        count += 1
      end
    end
  end
  puts "#{count} duplicates removed"
  
end