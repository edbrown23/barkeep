class AddReagents < ActiveRecord::Migration[6.1]
  def change
    create_table :reagents do |t|
      t.string :name
      t.decimal :cost
      t.string :purchase_location
      t.decimal :max_volume
      t.decimal :current_volume_percentage

      t.timestamps
    end
  end
end
