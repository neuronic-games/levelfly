task :update_show_outcome_tasks => :environment do
  tasks = Task.all
  tasks.each do |task|
    task.update_attributes(:show_outcomes => true)
  end

end