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
#  extras      :jsonb
#
class Recipe < ApplicationRecord
  has_many :reagent_amounts, dependent: :destroy

  class << self
    # could be a module, plus this is all probabyl dumb and a gem or whatever
    def extra_column(name, default = nil)
      define_method(name) do
        (extras || {})[name.to_s] || default
      end

      define_method("#{name}=") do |value|
        self.extras ||= {}
        self.extras[name.to_s] = value
      end
    end
  end

  extra_column :favorite, false
end
