task :report => :environment do
  Admin.list_members('2014-01-01', 'BMCC')
end