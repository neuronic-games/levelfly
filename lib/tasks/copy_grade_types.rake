# frozen_string_literal: true

namespace :levelfly do
  desc 'Copy grade types from <source> to <dest>; specify schools by code e.g.
    `rake levelfly:copy_grade_types source=BMCC dest=LEVELFLY`'
  task copy_grade_types: :environment do
    school_source = School.find_by!(code: ENV.fetch('source', nil))
    school_dest = School.find_by!(code: ENV.fetch('dest', nil))

    # rubocop:disable Rails/FindEach
    GradeType.where(school: school_source).each do |grade_type|
      duplicate = grade_type.dup
      duplicate.school = school_dest
      duplicate.save
    end
    # rubocop:enable Rails/FindEach
  end
end
