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

ActiveRecord::Schema[8.1].define(version: 2026_03_05_114116) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "article_requests", force: :cascade do |t|
    t.datetime "approved_at"
    t.string "approved_by"
    t.datetime "created_at", null: false
    t.text "notes"
    t.datetime "requested_at", null: false
    t.string "slug", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["requested_at"], name: "index_article_requests_on_requested_at"
    t.index ["slug"], name: "index_article_requests_on_slug", unique: true
    t.index ["status"], name: "index_article_requests_on_status"
  end

  create_table "article_versions", force: :cascade do |t|
    t.text "body_html", null: false
    t.text "body_markdown", null: false
    t.bigint "cached_article_id", null: false
    t.datetime "created_at", null: false
    t.datetime "generated_at", null: false
    t.string "model"
    t.text "note"
    t.jsonb "sources", default: [], null: false
    t.datetime "updated_at", null: false
    t.integer "version", null: false
    t.index ["cached_article_id", "version"], name: "index_article_versions_on_cached_article_id_and_version", unique: true
    t.index ["cached_article_id"], name: "index_article_versions_on_cached_article_id"
  end

  create_table "cached_articles", force: :cascade do |t|
    t.text "body_html", null: false
    t.text "body_markdown", null: false
    t.datetime "created_at", null: false
    t.datetime "generated_at", null: false
    t.string "model"
    t.integer "quality_score"
    t.datetime "reviewed_at"
    t.string "slug", null: false
    t.jsonb "sources", default: [], null: false
    t.string "status", default: "ok", null: false
    t.decimal "temperature", precision: 3, scale: 2
    t.string "title", null: false
    t.integer "tokens_used"
    t.datetime "updated_at", null: false
    t.integer "version", default: 1, null: false
    t.index ["generated_at"], name: "index_cached_articles_on_generated_at"
    t.index ["slug"], name: "index_cached_articles_on_slug", unique: true
    t.index ["sources"], name: "index_cached_articles_on_sources", using: :gin
    t.index ["status"], name: "index_cached_articles_on_status"
  end

  create_table "citation_events", force: :cascade do |t|
    t.decimal "corroboration_multiplier", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.decimal "domain_multiplier", precision: 5, scale: 2, null: false
    t.string "event_type", null: false
    t.string "rubric_version", null: false
    t.bigint "source_id", null: false
    t.bigint "topic_id", null: false
    t.decimal "total_weight", precision: 8, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.decimal "url_base_score", precision: 5, scale: 2, null: false
    t.bigint "user_id", null: false
    t.index ["source_id"], name: "index_citation_events_on_source_id"
    t.index ["topic_id"], name: "index_citation_events_on_topic_id"
    t.index ["user_id"], name: "index_citation_events_on_user_id"
  end

  create_table "domains", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "host", null: false
    t.decimal "reputation_modifier", precision: 5, scale: 2, default: "1.0", null: false
    t.datetime "updated_at", null: false
    t.index ["host"], name: "index_domains_on_host", unique: true
  end

  create_table "feedbacks", force: :cascade do |t|
    t.bigint "cached_article_id", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "feedback_created_at"
    t.string "rating", null: false
    t.datetime "updated_at", null: false
    t.index ["cached_article_id"], name: "index_feedbacks_on_cached_article_id"
    t.index ["rating"], name: "index_feedbacks_on_rating"
  end

  create_table "sources", force: :cascade do |t|
    t.string "canonical_url", null: false
    t.string "content_hash"
    t.datetime "created_at", null: false
    t.bigint "domain_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.decimal "url_base_score", precision: 5, scale: 2
    t.index ["canonical_url"], name: "index_sources_on_canonical_url", unique: true
    t.index ["domain_id"], name: "index_sources_on_domain_id"
  end

  create_table "topics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_topics_on_slug", unique: true
  end

  create_table "trust_scores", force: :cascade do |t|
    t.bigint "citation_event_id"
    t.datetime "created_at", null: false
    t.bigint "domain_id", null: false
    t.text "reason", null: false
    t.decimal "score_change", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["citation_event_id"], name: "index_trust_scores_on_citation_event_id"
    t.index ["domain_id"], name: "index_trust_scores_on_domain_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "access_token"
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "did", null: false
    t.string "display_name"
    t.string "handle"
    t.string "pds_endpoint"
    t.text "refresh_token"
    t.datetime "token_expires_at"
    t.datetime "updated_at", null: false
    t.index ["did"], name: "index_users_on_did", unique: true
  end

  add_foreign_key "article_versions", "cached_articles"
  add_foreign_key "citation_events", "sources"
  add_foreign_key "citation_events", "topics"
  add_foreign_key "citation_events", "users"
  add_foreign_key "feedbacks", "cached_articles"
  add_foreign_key "sources", "domains"
  add_foreign_key "trust_scores", "citation_events"
  add_foreign_key "trust_scores", "domains"
end
