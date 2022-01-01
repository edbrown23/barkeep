# == Schema Information
#
# Table name: recipes
#
#  id          :bigint           not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category    :string           not null
#  description :text
#
class Recipe < ApplicationRecord
  has_many :reagent_amounts, dependent: :destroy
end
