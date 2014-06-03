task :run_report => :environment do
  
  Admin.list_members(ENV['from'], ENV['school'])

end