class StartTheGreatTagsMigration < ActiveRecord::Migration[6.1]
  def change
    # Here's what's happening:
    # reagent amounts are linked indirectly to reagents via "tags"
    # which are a list of strings which point to which reagents satisfy
    # this amounts need. tags are actually just the external ids
    # of all ReagentCategories, which sit in the middle as a global
    # list of all possible tags.
    # For example, a cock and bull requires:
    # 1.5 oz [bourbon, rye]
    # 1.5 oz [benedictine]
    # 0.75 oz [cognac, brandy]
    # 0.25 oz [curacao, triple sec]
    # this will have to be indexed somehow for perf someday, but I don't
    # care right now
    add_column :reagent_amounts, :tags, :string, array: true, default: []
    # foreign keying directly to categories isn't necessary anymore
    remove_column :reagent_amounts, :reagent_category_id

    # reagents also have tags
    # So, we can have a bulleit bourbon which has the tag [bourbon]
    # but also more complex tags, like VSOP which could have [brandy, cognac]
    add_column :reagents, :tags, :string, array: true, default: []
    # reagents don't foreign key directly to categories anymore, they go via tags
    remove_column :reagents, :reagent_category_id

    # ReagentCategories stay the "same", in that their just a global
    # set of rows containing external_ids (their tag), and a description.
    # This way, I can have pithy text saying gin is good, etc. They're
    # global across all users, which probably isn't ideal, but it'll work
    # for now. There will be no way to edit them as a user, but you can
    # create new ones if you have a specialty booze

    # Finding which drinks a user can make is going to be expensive until
    # I can figure out the GIN indexes, but for now I'm going to not care
    # about that. We'll just iterate each cocktail and get its tags, then
    # intersect that with the tags the users reagents have. THat'll tell
    # us what drinks they can make, and we can get more specific from there

    # This is all better because we're going to be more dynamic. The less
    # strict relations between reagents and amounts means that you can
    # delete one without needing to fix all the others.
  end
end
