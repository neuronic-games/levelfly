module BadgeHelper
  def course_detail(course_id)
    @course = Course.find(course_id)
    if @course  
      return "#{@course.code}-#{@course.section}"
    end
    return nil
  end
  
  def profile_name(profile_id)
    @profile = Profile.find(profile_id)
      if @profile 
         return @profile.full_name
      end
    return nil
  end
  
  def quest_name(quest_id)
    game = Game.find(quest_id)
    return game.nil? ? nil : game.name
  end
end
