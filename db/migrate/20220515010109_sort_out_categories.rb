class SortOutCategories < ActiveRecord::Migration[6.1]
  def change
    # reagents are never referred to directly from amounts, and must go through caterogies
    remove_column :reagent_amounts, :reagent_id, :bigint
    # category can't be null anymore cause its the only way to refer to reagents
    change_column_null :reagent_amounts, :reagent_category_id, false
    # categories are the "always shared" concept across the app, allowing for recipe sharing
    # As such, they don't need user ids
    remove_column :reagent_categories, :user_id, :bigint
    # reagents must now only exist as part of categories
    change_column_null :reagents, :reagent_category_id, false
  end
end
