class Major < ActiveRecord::Base
  belongs_to :school
  has_many :profile

  def self.add(school_handle, majors)
    school = School.find_by_handle(school_handle)
    return unless school

    major_list = majors.split(',')
    major_list.each do |major|
      name = major.strip
      next if Major.where({ school_id: school.id, name: name }).first

      Major.create(school_id: school.id, name: name)
    end
  end
end
