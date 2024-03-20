class AddOverrideDimension < ActiveRecord::Migration[7.0]
  def change
    add_column :reagent_categories, :override_dimension_external_id, :string
  end
end
