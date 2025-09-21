# Creating new Semesters for all existing Schools

task create_semesters_for_existing_school: :environment do
  School.all.each do |school|
    next unless school.semesters.blank?

    Semester.create(name: 'Fall', start_month: 8, end_month: 12, school_id: school)
    Semester.create(name: 'Winter', start_month: 1, end_month: 1, school_id: school)
    Semester.create(name: 'Spring', start_month: 2, end_month: 5, school_id: school)
    Semester.create(name: 'Summer I', start_month: 6, end_month: 6, school_id: school)
    Semester.create(name: 'Summer II', start_month: 7, end_month: 7, school_id: school)
  end
end
