class AddIndicesForTextSearch < ActiveRecord::Migration
  def up
    execute "CREATE INDEX index_courses_on_lower_name_code 
             ON courses (lower(name), lower(code));"
    execute "CREATE INDEX index_profiles_on_lower_full_name 
             ON profiles (lower(full_name));"
    execute "CREATE INDEX index_tasks_on_lower_name_descr 
             ON tasks (lower(name), lower(descr));"
    execute "CREATE INDEX index_messages_on_lower_content_topic 
             ON messages (lower(content), lower(topic));"
  end

  def down
    execute "DROP INDEX index_courses_on_lower_name_code;"
    execute "DROP INDEX index_profiles_on_lower_full_name;"
    execute "DROP INDEX index_tasks_on_lower_name_descr;"
    execute "DROP INDEX index_messages_on_lower_content_topic;"
  end
end
