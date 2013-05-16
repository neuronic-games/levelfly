# Delete enteries from outcome_tasks for deleted dependent outcomes

task :cleanup_outcome_tasks => :environment do

  outcome_ids = Outcome.all.map(&:id)
  count = OutcomeTask.delete_all(["outcome_id not in (?)",outcome_ids])
  puts "#{count} outcome_tasks deleted that were dependent on deleted outcomes"

end