# == Schema Information
#
# Table name: reagent_categories
#
#  id                             :bigint           not null, primary key
#  name                           :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  description                    :text
#  external_id                    :string           not null
#  override_dimension_external_id :string
#
# Indexes
#
#  index_reagent_categories_on_external_id  (external_id) UNIQUE
#  index_reagent_categories_on_name         (name) UNIQUE
#
class ReagentCategory < ApplicationRecord
  has_many :reference_bottles, dependent: :destroy

  def reagents(current_user)
    Reagent.for_user(current_user).with_tags(external_id)
  end

  def reagent_amounts(current_user)
    ReagentAmount.for_user(current_user).with_tags(external_id)
  end

  def dimension
    if override_dimension_external_id.present?
      return ReagentCategory.find_by(external_id: override_dimension_external_id).id
    end

    id
  end
end
