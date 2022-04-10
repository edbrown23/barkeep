class AddUserScopeToModels < ActiveRecord::Migration[6.1]
  def change
    add_column :reagents, :user_id, :bigint
    add_index :reagents, :user_id

    add_column :reagent_categories, :user_id, :bigint
    add_index :reagent_categories, :user_id
    
    add_column :reagent_amounts, :user_id, :bigint
    add_index :reagent_amounts, :user_id

    add_column :recipes, :user_id, :bigint
    add_index :recipes, :user_id

    add_column :audits, :user_id, :bigint
    add_index :audits, :user_id
  end
end
