class Major < ActiveRecord::Base
  belongs_to :school
  has_many :profile
  
  def self.add(school_code, majors)
    school = School.find_by_code(school_code)
    return unless school
    
    major_list = majors.split(",")
    major_list.each do |major|
      name = major.strip
      next if Major.find(:first, :conditions => {:school_id => school.id, :name => name})
      
      Major.create(:school_id => school.id, :name => name)
    end
    
  end
end
