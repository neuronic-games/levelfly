# Remove duplicate task members that were created due to an invite bug

task remove_dup_members: :environment do
  list = TaskParticipant.all
  puts "Checking #{list.count} participants"
  count = 0
  remove_list = {}
  list.each do |tp|
    # Is this task assigned to a member? If not remove it.
    task = tp.task
    next if task.nil?

    unless Participant.is_member_of(Course.name, task.course_id, tp.profile_id)
      puts "++ Removing task_participants ##{tp.id}: status=#{tp.status} profile_type=#{tp.profile_type} assign_date=#{tp.assign_date} complete_date=#{tp.complete_date} xp_award_date=#{tp.xp_award_date}"
      # Remember what was removed so that we don't remove it again
      remove_list[tp.id] = true
      tp.destroy
      count += 1
    end

    next if remove_list.include?(tp.id)

    puts "Checking task_participants ##{tp.id}: status=#{tp.status} profile_type=#{tp.profile_type} assign_date=#{tp.assign_date} complete_date=#{tp.complete_date} xp_award_date=#{tp.xp_award_date}"
    dups = TaskParticipant.where(['task_id = ? and profile_id = ? and id <> ?', tp.task_id, tp.profile_id, tp.id])
    dups.each do |dup|
      next unless dup and dup.status == 'A' # assigned

      puts ">> Removing task_participants ##{dup.id}: status=#{dup.status} profile_type=#{dup.profile_type} assign_date=#{dup.assign_date} complete_date=#{dup.complete_date} xp_award_date=#{dup.xp_award_date}"
      # Remember what was removed so that we don't remove it again
      remove_list[dup.id] = true
      dup.destroy
      count += 1
    end
  end
  puts "#{count} duplicates removed"
end
