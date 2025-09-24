class AddIndicesForTextSearch < ActiveRecord::Migration[4.2]
  def up
    execute "CREATE INDEX index_courses_on_lower_name ON courses
             USING gin(to_tsvector('english', lower(name)));"
    execute "CREATE INDEX index_courses_on_lower_code ON courses
             USING gin(to_tsvector('english', lower(code)));"
    execute "CREATE INDEX index_profiles_on_lower_full_name ON profiles
             USING gin(to_tsvector('english',lower(full_name)));"
    execute "CREATE INDEX index_tasks_on_lower_name ON tasks
             USING gin(to_tsvector('english',lower(name)));"
    execute "CREATE INDEX index_tasks_on_lower_descr ON tasks
             USING gin(to_tsvector('english',lower(descr)));"
    execute "CREATE INDEX index_messages_on_lower_content ON messages
             USING gin(to_tsvector('english',lower(content)));"
    execute "CREATE INDEX index_messages_on_lower_topic ON messages
             USING gin(to_tsvector('english',lower(topic)));"
  end

  def down
    execute 'DROP INDEX index_courses_on_lower_name;'
    execute 'DROP INDEX index_courses_on_lower_code;'
    execute 'DROP INDEX index_profiles_on_lower_full_name;'
    execute 'DROP INDEX index_tasks_on_lower_name;'
    execute 'DROP INDEX index_tasks_on_lower_descr;'
    execute 'DROP INDEX index_messages_on_lower_content;'
    execute 'DROP INDEX index_messages_on_lower_topic;'
  end
end
