class SchoolGrade < ActiveRecord::Base
  belongs_to :school
  
  @@data = {}
  
  def self.init_defaults(school_id)
    return unless @@data[school_id].nil?

    school_grades = SchoolGrade.where(:school_id => school_id)

    data = {}
    school_grades.each do |school_grade|
      data[school_grade.letter] = school_grade.value
    end
    @@data[school_id] = data
  end
  
  def self.lookup_letter(school_id, letter)
    self.init_defaults(school_id)
    
    return @@data[school_id][letter]
  end
end
