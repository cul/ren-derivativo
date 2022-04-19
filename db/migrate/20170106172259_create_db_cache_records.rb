class CreateDbCacheRecords < ActiveRecord::Migration[4.2]
  def change
    create_table :db_cache_records do |t|
      t.string :pid
      t.text :data
      t.boolean :derivative_generation_in_progress, null: false, default: false

      t.timestamps null: false
    end

    add_index :db_cache_records, :pid, :unique => true
  end
end
