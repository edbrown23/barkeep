class AddAdminColumnToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :roles, :string, array: true, default: []
  end
end
