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

ActiveRecord::Schema.define(:version => 20120110080355) do

  create_table "postal_codes", :force => true do |t|
    t.string   "uid"
    t.string   "old_postal_code"
    t.string   "postal_code"
    t.string   "pref_kana"
    t.string   "city_kana"
    t.string   "town_kana"
    t.string   "pref"
    t.string   "city"
    t.string   "town"
    t.integer  "has_multiple_postal_code"
    t.integer  "multiple_koaza"
    t.integer  "has_chome"
    t.integer  "multiple_town"
    t.integer  "has_update"
    t.integer  "update_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tky2jgds", :force => true do |t|
    t.string   "meshcode"
    t.float    "dB"
    t.float    "dL"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tky2jgds", ["meshcode"], :name => "index_tky2jgds_on_meshcode"

end
