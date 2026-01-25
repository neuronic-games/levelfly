task update_F_grade_type: :environment do
  grade_types = GradeType.where(letter: 'F')
  grade_types.each { |g| g.update_attribute(:value, 55) }
end
