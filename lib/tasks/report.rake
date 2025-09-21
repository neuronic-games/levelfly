task :report, %i[report_name from_date school_code] => :environment do |_t, args|
  case args.report_name
  when 'all_members'
    Report.all_members(args.from_date, args.school_code)
  when 'course_members'
    Report.course_members(args.from_date, args.school_code)
  else
    puts 'e.g.'
    puts '  heroku run rake report[all_members,2014-02-01,BMCC]'
    puts '  heroku run rake report[course_members,2014-02-01,BMCC]'
  end
end
