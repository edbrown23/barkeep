class AddTextSearchToRecipes < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE FUNCTION extract_tags_from_blob(blob JSONB)
      RETURNS TEXT[] LANGUAGE SQL IMMUTABLE
      AS $$
        select
          array_agg(replace(tags, '_', '/'))
        from (
          select jsonb_array_elements_text(jsonb_array_elements(blob->'ingredients')->'tags') as tags
        ) t;
      $$;

      ALTER TABLE recipes
      ADD COLUMN searchable tsvector GENERATED ALWAYS AS (
        array_to_tsvector(extract_tags_from_blob(ingredients_blob))
      ) STORED;
    SQL
  end

  def down
    execute <<~SQL    
      DROP FUNCTION IF EXISTS extract_tags_from_blob(blob JSONB) RETURNS TEXT[];

      ALTER TABLE recipes DROP COLUMN searchable;
    SQL
  end
end
