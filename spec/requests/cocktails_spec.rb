require 'rails_helper'

RSpec.describe 'Cocktails', type: :request do
  include_context 'basic users'

  describe 'GET /cocktails/:id' do
    it 'shows an owned cocktail and its ingredient amount' do
      cocktail = create(:recipe, name: 'Negroni', user: test_user)
      create(
        :reagent_amount,
        recipe: cocktail,
        user: test_user,
        tags: ['gin'],
        amount: '1',
        unit: 'oz'
      )
      create(
        :reagent_amount,
        recipe: cocktail,
        user: test_user,
        tags: ['vermouth'],
        amount: '0.5',
        unit: 'oz'
      )
      sign_in test_user

      get cocktail_path(cocktail)

      expect(response).to be_successful
      expect(response.body).to include('Negroni', '1.0 oz', '0.5 oz')
      expect(response.body).to include('Servings', 'data-controller="cocktail-scale"')
      expect(response.body).to include(
        'data-cocktail-scale-base-amount="1.0"',
        'data-cocktail-scale-base-amount="0.5"'
      )
      expect(response.body.scan('data-cocktail-scale-target="amount"').count).to eq(2)
    end
  end
end
