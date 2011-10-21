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

ActiveRecord::Schema.define(:version => 20111021081329) do

  create_table "access_codes", :force => true do |t|
    t.integer  "campus_id"
    t.integer  "major_id"
    t.string   "code",           :limit => 32
    t.date     "available_date"
    t.boolean  "archived"
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
    t.string   "head",        :limit => 64
    t.string   "hair",        :limit => 64
    t.string   "hair_back",   :limit => 64
    t.string   "facial_1"
    t.string   "facial_2"
    t.string   "glasses",     :limit => 64
    t.string   "makeup",      :limit => 64
    t.string   "hat",         :limit => 64
    t.string   "earrings",    :limit => 64
    t.string   "jewelry",     :limit => 64
    t.string   "necklace",    :limit => 64
    t.string   "top",         :limit => 64
    t.string   "top_back",    :limit => 64
    t.string   "bottom",      :limit => 64
    t.string   "bottom_back", :limit => 64
    t.string   "shoes",       :limit => 64
    t.string   "prop_1",      :limit => 64
    t.string   "prop_2",      :limit => 64
    t.string   "background",  :limit => 64
    t.boolean  "archived"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "badges", :force => true do |t|
    t.string   "name",            :limit => 64
    t.date     "available_date"
    t.integer  "available_level"
    t.date     "visible_date"
    t.integer  "visible_level"
    t.integer  "quest_id"
    t.boolean  "archived"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "campus", :force => true do |t|
    t.string   "name",       :limit => 64
    t.string   "code",       :limit => 64
    t.boolean  "archived"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "campus_majors", :force => true do |t|
    t.integer  "campus_id"
    t.integer  "major_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "majors", :force => true do |t|
    t.string   "name",       :limit => 64
    t.string   "code",       :limit => 32
    t.boolean  "archived"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "profiles", :force => true do |t|
    t.integer  "user_id"
    t.integer  "campus_id"
    t.integer  "major_id"
    t.string   "code",       :limit => 64
    t.string   "name",       :limit => 64
    t.string   "full_name",  :limit => 64
    t.string   "salutation", :limit => 64
    t.boolean  "primary"
    t.boolean  "archived"
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
    t.boolean  "archived"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "wardrobe_items", :force => true do |t|
    t.integer  "wardrobe_id"
    t.string   "name",            :limit => 64
    t.string   "image_file",      :limit => 64
    t.integer  "parent_item_id"
    t.date     "available_date"
    t.integer  "available_level"
    t.date     "visible_date"
    t.integer  "visible_level"
    t.boolean  "archived"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "wardrobes", :force => true do |t|
    t.string   "name",            :limit => 64
    t.date     "available_date"
    t.integer  "available_level"
    t.date     "visible_date"
    t.integer  "visible_level"
    t.boolean  "archived"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
