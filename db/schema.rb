# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111123063151) do

  create_table "access_codes", :force => true do |t|
    t.integer  "school_id"
    t.integer  "major_id"
    t.string   "code",           :limit => 32
    t.date     "available_date"
    t.boolean  "archived",                     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "avatar_badges", :force => true do |t|
    t.integer  "avatar_id"
    t.integer  "badge_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "avatars", :force => true do |t|
    t.integer  "profile_id"
    t.integer  "level"
    t.integer  "points"
    t.integer  "badge_count"
    t.integer  "skin"
    t.string   "prop",         :limit => 64
    t.string   "hat",          :limit => 64
    t.string   "hair",         :limit => 64
    t.string   "glasses",      :limit => 64
    t.string   "makeup",       :limit => 64
    t.string   "facial_hair",  :limit => 64
    t.string   "facial_marks", :limit => 64
    t.string   "earrings",     :limit => 64
    t.string   "head",         :limit => 64
    t.string   "top",          :limit => 64
    t.string   "necklace",     :limit => 64
    t.string   "bottom",       :limit => 64
    t.string   "shoes",        :limit => 64
    t.string   "hair_back",    :limit => 64
    t.string   "hat_back",     :limit => 64
    t.string   "body",         :limit => 64
    t.string   "background",   :limit => 64
    t.boolean  "archived",                   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "eyes",         :limit => 64
    t.string   "nose",         :limit => 64
    t.string   "mouth",        :limit => 64
  end

  create_table "badges", :force => true do |t|
    t.string   "name",            :limit => 64
    t.date     "available_date"
    t.integer  "available_level"
    t.date     "visible_date"
    t.integer  "visible_level"
    t.integer  "quest_id"
    t.boolean  "archived",                      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories", :force => true do |t|
    t.string   "name",          :limit => 64
    t.boolean  "archived"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
    t.integer  "percent_value"
    t.integer  "campus_id"
  end

  create_table "courses", :force => true do |t|
    t.string   "name",       :limit => 64
    t.text     "descr"
    t.string   "code"
    t.integer  "campus_id"
    t.boolean  "archived"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "departments", :force => true do |t|
    t.string   "name",       :limit => 64
    t.text     "descr"
    t.string   "code"
    t.boolean  "archived"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "campus_id"
  end

  create_table "majors", :force => true do |t|
    t.integer  "school_id"
    t.string   "name",       :limit => 64
    t.string   "code",       :limit => 32
    t.boolean  "archived",                 :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "campus_id"
  end

  create_table "outcome_grades", :force => true do |t|
    t.integer  "campus_id"
    t.integer  "course_id"
    t.integer  "outcome_id"
    t.integer  "profile_id"
    t.integer  "grade"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "outcome_tasks", :force => true do |t|
    t.integer  "task_id"
    t.integer  "outcome_id"
    t.decimal  "points_percentage", :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "outcomes", :force => true do |t|
    t.string   "name",        :limit => 64
    t.text     "descr"
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
  end

  create_table "participants", :force => true do |t|
    t.integer  "object_id"
    t.string   "object_type",  :limit => 64
    t.integer  "profile_id"
    t.string   "profile_type", :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "profiles", :force => true do |t|
    t.integer  "user_id"
    t.integer  "school_id"
    t.integer  "major_id"
    t.string   "code",       :limit => 64
    t.string   "name",       :limit => 64
    t.string   "full_name",  :limit => 64
    t.string   "salutation", :limit => 64
    t.boolean  "primary",                  :default => false
    t.boolean  "archived",                 :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "quests", :force => true do |t|
    t.string   "name",            :limit => 64
    t.integer  "points"
    t.date     "available_date"
    t.integer  "available_level"
    t.date     "visible_date"
    t.integer  "visible_level"
    t.boolean  "archived",                      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "campus_id"
  end

  create_table "schools", :force => true do |t|
    t.string   "name",       :limit => 64
    t.string   "code",       :limit => 64
    t.boolean  "archived",                 :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "task_grades", :force => true do |t|
    t.integer  "campus_id"
    t.integer  "course_id"
    t.integer  "task_id"
    t.integer  "profile_id"
    t.integer  "grade"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", :force => true do |t|
    t.string   "name",           :limit => 64
    t.text     "descr"
    t.date     "due_date"
    t.date     "available_date"
    t.date     "visible_date"
    t.integer  "category_id"
    t.boolean  "notify_wall"
    t.boolean  "is_template"
    t.boolean  "archived"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "campus_id"
    t.integer  "course_id"
    t.integer  "level"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => "", :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "wardrobe_items", :force => true do |t|
    t.integer  "wardrobe_id"
    t.string   "name",            :limit => 64
    t.string   "item_type",       :limit => 64
    t.string   "image_file",      :limit => 64
    t.string   "icon_file",       :limit => 64
    t.integer  "parent_item_id"
    t.date     "available_date"
    t.integer  "available_level"
    t.date     "visible_date"
    t.integer  "visible_level"
    t.integer  "sort_order"
    t.integer  "depth"
    t.boolean  "archived",                      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "wardrobes", :force => true do |t|
    t.string   "name",            :limit => 64
    t.date     "available_date"
    t.integer  "available_level"
    t.date     "visible_date"
    t.integer  "visible_level"
    t.boolean  "archived",                      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
