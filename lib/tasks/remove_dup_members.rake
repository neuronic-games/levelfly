# Remove duplicate task members that were created due to an invite bug

task :remove_dup_members => :environment do
  list = TaskParticipant.all
  puts "Checking #{list.count} participants"
  count = 0
  remove_list = {}
  list.each do |tp|
    next if remove_list.contains(tp.id)
    puts "Checking task_participants ##{tp.id}: status=#{tp.status} profile_type=#{tp.profile_type} assign_date=#{tp.assign_date} complete_date=#{tp.complete_date} xp_award_date=#{tp.xp_award_date}"
    dups = TaskParticipant.find(:all, :conditions => ["task_id = ? and profile_id = ? and id <> ?", tp.task_id, tp.profile_id, tp.id])
    dups.each do |dup|
      if dup and dup.status == 'A'  # assigned
        puts "Removing task_participants ##{dup.id}: status=#{dup.status} profile_type=#{dup.profile_type} assign_date=#{dup.assign_date} complete_date=#{dup.complete_date} xp_award_date=#{dup.xp_award_date}"
        # We only want to delete this if this is not complete
        remove_list[dup.id] = tp.id
        # dup.destroy
        count += 1
      end
    end
  end
  puts "#{count} duplicates removed"
  
end