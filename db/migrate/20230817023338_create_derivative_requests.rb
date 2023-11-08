class CreateDerivativeRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :derivative_requests do |t|
      t.string  :identifier, null: false
      t.text :requested_derivatives, null: false
      t.integer :status, null: false, default: 0, index: true
      t.text  :error_message
      t.string :delivery_target, null: false
      t.text :main_uri, null: false
      t.text :access_uri
      t.text :poster_uri
      t.timestamps null: false
    end

    add_index :derivative_requests, :identifier, unique: true
  end
end
