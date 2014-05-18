task :report => :environment, :message do |t, args| do

  args.with_defaults(:message => "Thanks for logging on")
  puts ":message = #{:message}"
    
  Admin.list_members('2014-01-01', 'BMCC')
end