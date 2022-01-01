# == Schema Information
#
# Table name: reagent_categories
#
#  id          :bigint           not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  description :text
#
class ReagentCategory < ApplicationRecord
  has_many :reagents

  def category_available?(needed_amount)
    reagents.any? { |reagent| reagent.ounces_available >= needed_amount }
  end
end
