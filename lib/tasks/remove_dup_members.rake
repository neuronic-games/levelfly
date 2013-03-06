# Remove duplicate task members that were created due to an invite bug

task :remove_dup_members => :environment do
  list = TaskParticipant.all
  list.each do |tp|
    dup = TaskParticipant.find(:first, :conditions => ["task_id = ? and profile_id = ?", tp.task_id, tp.profile_id])
    if dup.complete_date.null?
      # We only want to delete this if this is not complete
      dup.destroy
    end
  end
end