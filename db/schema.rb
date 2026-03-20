# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_02_11_101507) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "access_codes", id: :serial, force: :cascade do |t|
    t.integer "school_id"
    t.integer "major_id"
    t.string "code", limit: 32
    t.date "available_date"
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attachments", id: :serial, force: :cascade do |t|
    t.string "target_type", limit: 64
    t.integer "target_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "resource_file_name", limit: 255
    t.string "resource_content_type", limit: 255
    t.integer "resource_file_size"
    t.integer "school_id"
    t.integer "owner_id"
    t.boolean "starred", default: false
  end

  create_table "avatar_badges", id: :serial, force: :cascade do |t|
    t.integer "badge_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "course_id"
    t.integer "profile_id"
    t.integer "giver_profile_id"
  end

  create_table "avatars", id: :serial, force: :cascade do |t|
    t.integer "profile_id"
    t.integer "skin"
    t.string "prop", limit: 64
    t.string "hat", limit: 64
    t.string "hair", limit: 64
    t.string "glasses", limit: 64
    t.string "facial_hair", limit: 64
    t.string "facial_marks", limit: 64
    t.string "earrings", limit: 64
    t.string "head", limit: 64
    t.string "top", limit: 64
    t.string "necklace", limit: 64
    t.string "bottom", limit: 64
    t.string "shoes", limit: 64
    t.string "hair_back", limit: 64
    t.string "hat_back", limit: 64
    t.string "body", limit: 64
    t.string "background", limit: 64
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "face", limit: 64
  end

  create_table "badge_images", id: :serial, force: :cascade do |t|
    t.string "image_file_name", limit: 255
    t.string "image_content_type", limit: 255
    t.integer "image_file_size"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "badges", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64
    t.date "available_date"
    t.integer "available_level"
    t.date "visible_date"
    t.integer "visible_level"
    t.integer "quest_id"
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "school_id"
    t.integer "badge_image_id"
    t.integer "creator_profile_id"
    t.string "descr", limit: 255
    t.integer "available_badge_image_id"
  end

  create_table "campus_majors", id: :serial, force: :cascade do |t|
    t.integer "campus_id"
    t.integer "major_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "categories", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64
    t.boolean "archived"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "course_id"
    t.integer "percent_value"
    t.integer "school_id"
  end

  create_table "checkpoints", id: :serial, force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "profile_id", null: false
    t.text "checkpoint"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["profile_id", "game_id"], name: "index_checkpoints_on_profile_id_and_game_id"
  end

  create_table "course_grades", id: :serial, force: :cascade do |t|
    t.integer "school_id"
    t.integer "course_id"
    t.integer "outcome_id"
    t.integer "profile_id"
    t.decimal "grade", precision: 5, scale: 2, default: "0.0"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "notes", limit: 255
    t.index ["profile_id", "course_id", "outcome_id"], name: "index_course_grades_on_profile_id_and_course_id_and_outcome_id"
  end

  create_table "courses", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64
    t.text "descr"
    t.string "code", limit: 255
    t.integer "school_id"
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "image_file_name", limit: 255
    t.string "image_content_type", limit: 255
    t.integer "image_file_size"
    t.string "section", limit: 255
    t.integer "rating_low"
    t.integer "rating_medium"
    t.integer "rating_high"
    t.integer "tasks_low"
    t.integer "tasks_medium"
    t.integer "tasks_high"
    t.string "parent_type", limit: 1, default: "C"
    t.string "visibility_type", limit: 1, default: "A"
    t.string "join_type", limit: 1, default: "I"
    t.datetime "grading_completed_at", precision: nil
    t.boolean "post_messages", default: true
    t.boolean "removed", default: false
    t.integer "course_id", default: 0
    t.boolean "all_members", default: true
    t.boolean "show_grade", default: true
    t.boolean "display_number_grades", default: false
    t.boolean "show_outcomes", default: true
    t.string "semester", limit: 255
    t.integer "year"
    t.boolean "allow_uploads"
    t.index "to_tsvector('english'::regconfig, lower((code)::text))", name: "index_courses_on_lower_code", using: :gin
    t.index "to_tsvector('english'::regconfig, lower((name)::text))", name: "index_courses_on_lower_name", using: :gin
  end

  create_table "courses_outcomes", id: false, force: :cascade do |t|
    t.integer "course_id"
    t.integer "outcome_id"
    t.index ["course_id", "outcome_id"], name: "index_courses_outcomes_on_course_id_and_outcome_id"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by", limit: 255
    t.string "queue", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "departments", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64
    t.text "descr"
    t.string "code", limit: 255
    t.boolean "archived"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "school_id"
  end

  create_table "feats", id: :serial, force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "profile_id", null: false
    t.integer "progress"
    t.integer "progress_type", null: false
    t.string "level", limit: 255
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["profile_id", "game_id"], name: "index_feats_on_profile_id_and_game_id"
  end

  create_table "feeds", id: :serial, force: :cascade do |t|
    t.integer "profile_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "wall_id"
  end

  create_table "game_schools", id: :serial, force: :cascade do |t|
    t.integer "game_id"
    t.integer "school_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["game_id", "school_id"], name: "index_game_schools_on_game_id_and_school_id"
  end

  create_table "game_score_leaders", id: :serial, force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "profile_id", null: false
    t.string "full_name", limit: 255
    t.integer "score"
    t.index ["profile_id", "game_id"], name: "index_game_score_leaders_on_profile_id_and_game_id"
  end

  create_table "games", id: :serial, force: :cascade do |t|
    t.string "handle", limit: 255
    t.string "name", limit: 255
    t.text "descr"
    t.string "image", limit: 255
    t.string "last_rev", limit: 255
    t.datetime "last_rev_date", precision: nil
    t.integer "player_count", default: 0
    t.boolean "published", default: false
    t.datetime "first_publish_date", precision: nil
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "image_file_name", limit: 255
    t.string "image_content_type", limit: 255
    t.integer "image_file_size"
    t.integer "school_id"
    t.integer "profile_id"
    t.text "download_links"
    t.string "mail_to", limit: 255
    t.integer "course_id"
    t.index ["archived", "published", "handle"], name: "index_games_on_archived_and_published_and_handle"
    t.index ["archived", "published", "name"], name: "index_games_on_archived_and_published_and_name"
  end

  create_table "games_outcomes", id: false, force: :cascade do |t|
    t.integer "game_id"
    t.integer "outcome_id"
    t.index ["game_id", "outcome_id"], name: "index_games_outcomes_on_game_id_and_outcome_id"
  end

  create_table "grade_types", id: :serial, force: :cascade do |t|
    t.integer "school_id"
    t.integer "course_id"
    t.string "letter", limit: 2
    t.decimal "value", precision: 4, scale: 2
    t.decimal "value_min", precision: 4, scale: 2
    t.decimal "gpa", precision: 2, scale: 1, default: "0.0", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["course_id"], name: "index_grade_types_on_course_id"
    t.index ["school_id"], name: "index_grade_types_on_school_id"
  end

  create_table "groups", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.text "descr"
    t.integer "course_id"
    t.integer "task_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "image_file_name", limit: 255
    t.string "image_content_type", limit: 255
    t.integer "image_file_size"
  end

  create_table "likes", id: :serial, force: :cascade do |t|
    t.integer "profile_id"
    t.integer "message_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "course_id"
  end

  create_table "majors", id: :serial, force: :cascade do |t|
    t.integer "school_id"
    t.string "name", limit: 64
    t.string "code", limit: 32
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "campus_id"
  end

  create_table "message_viewers", id: :serial, force: :cascade do |t|
    t.integer "message_id"
    t.integer "poster_profile_id"
    t.integer "viewer_profile_id"
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "viewed", default: false
    t.index ["poster_profile_id", "viewer_profile_id"], name: "index_message_viewers_on_poster_and_viewer"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.integer "profile_id"
    t.integer "parent_id"
    t.string "parent_type", limit: 64
    t.text "content"
    t.datetime "post_date", precision: nil
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "like", default: 0
    t.string "message_type", limit: 32, default: "Message"
    t.integer "wall_id"
    t.integer "target_id"
    t.string "target_type", limit: 255
    t.string "topic", limit: 255
    t.boolean "starred", default: false
    t.index "to_tsvector('english'::regconfig, lower((topic)::text))", name: "index_messages_on_lower_topic", using: :gin
    t.index "to_tsvector('english'::regconfig, lower(content))", name: "index_messages_on_lower_content", using: :gin
    t.index ["profile_id", "parent_id"], name: "index_messages_on_profile_id_and_parent_id"
  end

  create_table "notes", id: :serial, force: :cascade do |t|
    t.integer "profile_id"
    t.integer "about_object_id"
    t.string "about_object_type", limit: 64
    t.text "content"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "outcome_feats", id: :serial, force: :cascade do |t|
    t.integer "feat_id"
    t.integer "outcome_id"
    t.integer "profile_id"
    t.integer "rating"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["profile_id", "outcome_id", "feat_id"], name: "index_outcome_feats_on_profile_id_and_outcome_id_and_feat_id"
  end

  create_table "outcome_grades", id: :serial, force: :cascade do |t|
    t.integer "school_id"
    t.integer "course_id"
    t.integer "outcome_id"
    t.integer "profile_id"
    t.integer "grade"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "task_id"
  end

  create_table "outcome_tasks", id: :serial, force: :cascade do |t|
    t.integer "task_id"
    t.integer "outcome_id"
    t.decimal "points_percentage", precision: 10
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "outcomes", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64
    t.text "descr"
    t.integer "category_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "school_id"
    t.boolean "shared", default: false
    t.integer "created_by"
    t.integer "game_id"
  end

  create_table "participants", id: :serial, force: :cascade do |t|
    t.integer "target_id"
    t.string "target_type", limit: 64
    t.integer "profile_id"
    t.string "profile_type", limit: 1
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "permissions", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "permissions_role_names", id: :serial, force: :cascade do |t|
    t.integer "permission_id"
    t.integer "role_name_id"
  end

  create_table "profile_actions", id: :serial, force: :cascade do |t|
    t.integer "profile_id"
    t.string "action_type", limit: 10
    t.string "action_param", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "profiles", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "school_id"
    t.integer "major_id"
    t.string "code", limit: 64
    t.string "name", limit: 64
    t.string "full_name", limit: 64
    t.string "salutation", limit: 64
    t.boolean "primary", default: false
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "like_given", default: 0
    t.integer "like_received", default: 0
    t.integer "post_count", default: 0
    t.string "image_file_name", limit: 255
    t.string "image_content_type", limit: 255
    t.integer "image_file_size"
    t.integer "xp", default: 0
    t.integer "badge_count", default: 0
    t.integer "level", default: 1
    t.text "contact_info"
    t.integer "wardrobe", default: 1
    t.text "interests"
    t.boolean "all_comments", default: true
    t.string "post_date_format", limit: 255, default: "D"
    t.integer "role_name_id"
    t.boolean "extended_logout"
    t.boolean "is_public"
    t.boolean "friend_privilege"
    t.index "to_tsvector('english'::regconfig, lower((full_name)::text))", name: "index_profiles_on_lower_full_name", using: :gin
  end

  create_table "quests", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64
    t.integer "points"
    t.date "available_date"
    t.integer "available_level"
    t.date "visible_date"
    t.integer "visible_level"
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "school_id"
  end

  create_table "rewards", id: :serial, force: :cascade do |t|
    t.integer "xp"
    t.string "target_type", limit: 16
    t.integer "target_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "role_names", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name", limit: 16
    t.integer "profile_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "schools", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64
    t.string "code", limit: 64
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "handle", limit: 16
    t.string "student_code", limit: 255
    t.string "teacher_code", limit: 255
  end

  create_table "screen_shots", id: :serial, force: :cascade do |t|
    t.integer "game_id"
    t.string "image_file_name", limit: 255
    t.string "image_content_type", limit: 255
    t.integer "image_file_size"
    t.datetime "image_updated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "semesters", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "start_month"
    t.integer "end_month"
    t.integer "school_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["school_id"], name: "index_semesters_on_school_id"
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.integer "target_id"
    t.string "target_type", limit: 255
    t.string "name", limit: 255
    t.string "value", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type", limit: 255
    t.integer "tagger_id"
    t.string "tagger_type", limit: 255
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "task_grades", id: :serial, force: :cascade do |t|
    t.integer "school_id"
    t.integer "course_id"
    t.integer "task_id"
    t.integer "profile_id"
    t.decimal "grade", precision: 5, scale: 2
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "points"
  end

  create_table "task_participants", id: :serial, force: :cascade do |t|
    t.integer "profile_id"
    t.integer "task_id"
    t.datetime "assign_date", precision: nil
    t.datetime "complete_date", precision: nil
    t.string "profile_type", limit: 1
    t.string "priority", limit: 1
    t.string "status", limit: 1
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "extra_credit", default: false
    t.datetime "xp_award_date", precision: nil
  end

  create_table "tasks", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64
    t.text "descr"
    t.date "due_date"
    t.date "available_date"
    t.date "visible_date"
    t.integer "category_id"
    t.boolean "notify_wall"
    t.boolean "is_template"
    t.boolean "archived"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "school_id"
    t.integer "course_id"
    t.integer "level"
    t.string "image_file_name", limit: 255
    t.string "image_content_type", limit: 255
    t.integer "image_file_size"
    t.integer "points", default: 0
    t.boolean "extra_credit", default: false
    t.boolean "show_outcomes", default: true
    t.boolean "include_task_grade", default: true
    t.datetime "grading_complete_date", precision: nil
    t.boolean "all_members", default: false
    t.index "to_tsvector('english'::regconfig, lower((name)::text))", name: "index_tasks_on_lower_name", using: :gin
    t.index "to_tsvector('english'::regconfig, lower(descr))", name: "index_tasks_on_lower_descr", using: :gin
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "email", limit: 255, null: false
    t.string "encrypted_password", limit: 255, null: false
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.string "status", limit: 1, default: "A"
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email", limit: 255
    t.integer "default_school_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vaults", id: :serial, force: :cascade do |t|
    t.string "vault_type", limit: 32
    t.integer "target_id"
    t.string "target_type", limit: 64
    t.string "account", limit: 255
    t.string "secret", limit: 255
    t.string "folder", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "walls", id: :serial, force: :cascade do |t|
    t.integer "parent_id"
    t.string "parent_type", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "wardrobe_item_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 32
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "wardrobe_items", id: :serial, force: :cascade do |t|
    t.integer "wardrobe_id"
    t.string "name", limit: 64
    t.string "item_type", limit: 64
    t.string "image_file", limit: 250
    t.string "icon_file", limit: 250
    t.integer "parent_item_id"
    t.date "available_date"
    t.integer "available_level"
    t.date "visible_date"
    t.integer "visible_level"
    t.integer "sort_order"
    t.integer "depth"
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "wardrobes", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64
    t.date "available_date"
    t.integer "available_level"
    t.date "visible_date"
    t.integer "visible_level"
    t.boolean "archived", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
