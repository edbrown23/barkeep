# == Schema Information
#
# Table name: audits
#
#  id         :bigint           not null, primary key
#  recipe_id  :bigint           not null
#  info       :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#
# Indexes
#
#  index_audits_on_recipe_id  (recipe_id)
#  index_audits_on_user_id    (user_id)
#
class Audit < ApplicationRecord
  include UserScopable

  belongs_to :recipe  

  ReagentUsed = Struct.new(:name, :amount, :unit, :description, keyword_init: true)

  def backup_name
    info['cocktail_name']
  end

  def reagents
    @reagents ||= info['reagents'].map do |used|
      ReagentUsed.new(
        name: used['reagent_name'],
        amount: used['amount_used'],
        unit: used['unit_used'],
        description: used['description']
      )
    end
  end
end
