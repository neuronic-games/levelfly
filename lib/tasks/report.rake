task :report, [:from_date, :school_code] => :environment do |t, args|

  Report.list_members(args.from_date, args.school_code)
  
end