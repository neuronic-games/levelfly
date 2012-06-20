class GradeType < ActiveRecord::Base
  belongs_to :school
  belongs_to :course
  
  @@data = {}
  
  def self.init_defaults(school_id)
    return unless @@data[school_id].nil?

    grade_types = GradeType.where(:school_id => school_id).order("value desc")

    data = {}

    # These arrays are used for quick conversion of percent value to letter grade
    data["value_min"] = []
    data["letter"] = []

    grade_types.each do |grade_type|
      data[grade_type.letter] = grade_type.value
      data["value_min"] << grade_type.value_min
      data["letter"] << grade_type.letter
    end
    @@data[school_id] = data
  end
  
  def self.reset
    @@data = {}
  end
  
  # Convert a letter grade (e.g. B+) to a grade percent value (e.g. 88.33)
  def self.letter_to_value(letter, school_id)
    self.init_defaults(school_id)
    return @@data[school_id][letter]
  end
  
  # Convert a grade percent value to a letter grade
  def self.value_to_letter(value, school_id)
    self.init_defaults(school_id)
    
    letter = nil
    idx = 0
    @@data[school_id]["value_min"].each do |value_min|
      if value_min > value
        idx += 1
        next
      end

      letter = @@data[school_id]["letter"][idx]
      break
    end
    
    return letter
  end
  
  def self.is_num(num)
    if num =~ /^[-+]?[0-9]*\.?[0-9]+$/
      return true
    else
      return false  
    end
   
  end
  
end
