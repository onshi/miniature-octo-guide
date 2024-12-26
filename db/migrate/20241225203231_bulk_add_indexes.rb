class BulkAddIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :users, :email, unique: true
    add_index :users, :preferred_price_range, using: :gist

    add_index :cars, :price
    add_index :cars, [:brand_id, :price]

    add_index :brands, :name, unique: true

    add_index :user_preferred_brands, [:user_id, :brand_id], unique: true
  end
end
