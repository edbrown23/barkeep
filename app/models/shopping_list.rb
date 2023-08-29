# == Schema Information
#
# Table name: shopping_lists
#
#  id         :bigint           not null, primary key
#  name       :string
#  user_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_shopping_lists_on_user_id  (user_id)
#
class ShoppingList < ApplicationRecord
  include UserScopable

  has_many :reagents
end
