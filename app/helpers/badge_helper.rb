module BadgeHelper
  def course_detail(course_id)
    @course = Course.find(course_id)
    return "#{@course.code}-#{@course.section}" if @course

    nil
  end

  def profile_name(profile_id)
    @profile = Profile.find(profile_id)
    return @profile.full_name if @profile

    nil
  end

  def quest_name(quest_id)
    game = Game.find(quest_id)
    game.nil? ? nil : game.name
  end
end
