class CorrectUniqueIndexesAgain < ActiveRecord::Migration[6.1]
  def change
    remove_index :reagents, :name, unique: true
    add_index :reagents, [:name, :user_id], unique: true
  end
end
