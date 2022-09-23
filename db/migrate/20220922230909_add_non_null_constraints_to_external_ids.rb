class AddNonNullConstraintsToExternalIds < ActiveRecord::Migration[6.1]
  def change
    change_column_null :reagents, :external_id, false
    change_column_null :reagent_categories, :external_id, false
  end
end
