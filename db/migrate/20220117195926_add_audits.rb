class AddAudits < ActiveRecord::Migration[6.1]
  def change
    create_table :audits do |t|
      t.references :recipe, null: false
      t.jsonb :info, null: false

      t.timestamps
    end
  end
end
