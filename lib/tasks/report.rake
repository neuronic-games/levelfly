task :report, [:report_name, :from_date, :school_code] => :environment do |t, args|

  case args.report_name
  when 'members'
    Report.list_members(args.from_date, args.school_code)
  when 'summary'
    Report.summary(args.from_date, args.school_code)
  end
  
end