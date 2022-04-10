# == Schema Information
#
# Table name: reagent_categories
#
#  id          :bigint           not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  description :text
#  user_id     :bigint
#
# Indexes
#
#  index_reagent_categories_on_user_id  (user_id)
#
class ReagentCategory < ApplicationRecord
  include UserScopable

  has_many :reagents

  def category_available?(needed_amount)
    reagents.any? { |reagent| reagent.ounces_available >= needed_amount }
  end
end
