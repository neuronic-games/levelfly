task run_report: :environment do
  Admin.list_members(ENV.fetch('from', nil), ENV.fetch('school', nil))
end
