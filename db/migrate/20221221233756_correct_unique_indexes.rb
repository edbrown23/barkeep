class CorrectUniqueIndexes < ActiveRecord::Migration[6.1]
  def change
    remove_index :reagents, :external_id, unique: true
    add_index :reagents, [:external_id, :user_id], unique: true
  end
end
