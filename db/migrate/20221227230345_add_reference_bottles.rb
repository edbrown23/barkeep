class AddReferenceBottles < ActiveRecord::Migration[6.1]
  def change
    create_table :reference_bottles do |t|
      t.string :name, null: false
      t.decimal :cost_reference
      t.string :description
      t.string :main_image_url
      t.belongs_to :reagent_category

      t.timestamps
    end
  end
end
