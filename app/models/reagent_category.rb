# == Schema Information
#
# Table name: reagent_categories
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ReagentCategory < ApplicationRecord
  has_many :reagents
end
