class CreateShoppingLists < ActiveRecord::Migration[7.0]
  def change
    create_table :shopping_lists do |t|
      t.string :name
      t.references :user, null: false

      t.timestamps
    end

    add_reference :reagents, :shopping_list
  end
end
