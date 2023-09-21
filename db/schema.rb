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

ActiveRecord::Schema[7.0].define(version: 2023_08_17_023338) do
  create_table "derivative_requests", force: :cascade do |t|
    t.string "identifier", null: false
    t.text "requested_derivatives", null: false
    t.integer "status", default: 0, null: false
    t.text "error_message"
    t.string "delivery_target", null: false
    t.text "main_uri", null: false
    t.text "access_uri"
    t.text "poster_uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_derivative_requests_on_identifier", unique: true
    t.index ["status"], name: "index_derivative_requests_on_status"
  end

end
