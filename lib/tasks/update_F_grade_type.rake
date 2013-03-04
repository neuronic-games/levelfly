task :update_F_grade_type => :environment do
   grade_types = GradeType.find_all_by_letter("F")
   grade_types.each {|g| g.update_attribute(:value, 55)}
end