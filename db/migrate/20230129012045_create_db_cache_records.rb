class CreateDbCacheRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :db_cache_records do |t|
      t.string  :identifier, null: false
      t.boolean :processing, null: false, default: false
      t.string  :use_placeholder_image
      t.integer :base_width
      t.integer :base_height
      t.timestamps null: false
    end

    add_index :db_cache_records, :identifier, :unique => true
  end
end
