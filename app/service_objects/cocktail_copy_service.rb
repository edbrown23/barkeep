class CocktailCopyService
  def self.customize(source, user)
    raise ActiveRecord::RecordNotFound unless source.shared? && source.category == 'cocktail' && user.present?

    Recipe.transaction { duplicate(source, user: user, parent: source) }
  end

  def self.publish(source)
    source.with_lock do
      raise ActiveRecord::RecordNotFound unless source.category == 'cocktail' && !source.shared? && source.proposed_to_be_shared

      copy = duplicate(source, user: nil, parent: nil)
      source.update!(proposed_to_be_shared: false, proposer_user_id: nil)
      copy
    end
  end

  def self.duplicate(source, user:, parent:)
    copy = source.dup
    copy.assign_attributes(user: user, parent: parent, proposed_to_be_shared: false, proposer_user_id: nil)
    copy.clear_ingredients
    copy.save!
    source.reagent_amounts.each do |amount|
      copied_amount = amount.dup
      copied_amount.assign_attributes(recipe: copy, user: user)
      copied_amount.save!
      copy << copied_amount.convert_to_blob
    end
    copy.save!
    copy
  end
  private_class_method :duplicate
end
