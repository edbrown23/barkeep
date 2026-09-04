require 'rails_helper'

RSpec.describe ShoppingList, type: :model do
  it_behaves_like 'a user-scoped model', :shopping_list, supports_shared: false

  describe 'reagents' do
    it 'traverses bottles assigned to the list' do
      shopping_list = create(:shopping_list)
      placeholder = create(:reagent, user: shopping_list.user, shopping_list: shopping_list)

      expect(shopping_list.reagents).to contain_exactly(placeholder)
    end

    it 'destroys its placeholders without touching ordinary inventory' do
      shopping_list = create(:shopping_list)
      placeholder = create(:reagent, user: shopping_list.user, shopping_list: shopping_list)
      inventory_bottle = create(:reagent, user: shopping_list.user)

      shopping_list.destroy!

      expect(Reagent.exists?(placeholder.id)).to be(false)
      expect(Reagent.exists?(inventory_bottle.id)).to be(true)
    end
  end
end
