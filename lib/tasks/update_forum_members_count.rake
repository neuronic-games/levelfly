# remove forum members that no more belongs to course

task :update_forum_members_count => :environment do
  courses = Course.where("removed = ?",false)
  courses.each do |course|
    forums = Course.where(course_id: course.id)
    forums.each do |forum|
      course_participants = Profile.where( ["participants.target_id = ? AND participants.target_type IN ('Course','Group') AND participants.profile_type = 'S'", course.id])
        .include([:participants])
        .map(&:id)
      count = Participant.delete_all(["participants.target_id = ? AND participants.target_type IN ('Course','Group') AND participants.profile_type = 'S' AND participants.profile_id not in (?)", forum.id, course_participants])
      puts "#{count} forum members deleted"
    end
  end
end
