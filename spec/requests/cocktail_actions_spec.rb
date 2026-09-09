require 'rails_helper'

RSpec.describe 'Cocktail actions', type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user, roles: ['admin']) }
  let(:shared) { create(:recipe) }
  let(:owned) { create(:recipe, user: user) }
  let(:foreign) { create(:recipe, user: create(:user)) }

  it 'requires login for every mutation including legacy shared routes' do
    paths = [cocktail_add_to_account_path(shared), cocktail_promote_to_shared_path(owned), cocktail_propose_to_share_path(owned), cocktail_make_permanent_path(owned), cocktail_toggle_favorite_path(shared), shared_cocktail_promote_to_shared_path(owned)]
    paths.each do |path|
      post path, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
    delete shared_cocktail_path(shared), as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it 'only allows copying shared cocktails through either route' do
    [cocktail_add_to_account_path(shared), shared_cocktail_add_to_account_path(shared)].each do |path|
      sign_in user
      expect { post path, as: :json }.to change(Recipe, :count).by(1)
      expect(response.parsed_body).to include('action' => 'add_to_account', 'cocktail_name' => shared.name)
    end
    [foreign, owned, create(:recipe, category: 'other')].each do |recipe|
      sign_in user
      post cocktail_add_to_account_path(recipe), as: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  it 'returns working HTML and Turbo copy responses' do
    sign_in user
    post cocktail_add_to_account_path(shared)
    expect(response).to redirect_to(cocktail_path(Recipe.order(:id).last))
    post cocktail_add_to_account_path(shared), headers: { 'ACCEPT' => 'text/vnd.turbo-stream.html' }
    expect(response).to be_successful
    expect(response.body).to include('target="usersVersions"', 'target="toastDestination"', 'added to your account!')
  end

  it 'restricts proposals and permanent conversion to the owner' do
    [shared, foreign].each do |recipe|
      [cocktail_propose_to_share_path(recipe), cocktail_make_permanent_path(recipe)].each do |path|
        sign_in user
        post path, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
    sign_in user
    post cocktail_propose_to_share_path(owned), as: :json
    expect(owned.reload).to have_attributes(proposed_to_be_shared: true, proposer_user_id: user.id)
    owned.update!(source: 'drink_builder')
    post cocktail_make_permanent_path(owned), as: :json
    expect(owned.reload.source).to eq('')
  end

  it 'requires admin permission and a pending personal proposal for publication' do
    owned.update!(proposed_to_be_shared: true)
    sign_in user
    post cocktail_promote_to_shared_path(owned), as: :json
    expect(response).to have_http_status(:forbidden)
    sign_in admin
    expect { post shared_cocktail_promote_to_shared_path(owned), as: :json }.to change(Recipe.shared, :count).by(1)
    expect(response).to be_successful
    post cocktail_promote_to_shared_path(owned), as: :json
    expect(response).to have_http_status(:not_found)
  end

  it 'favorites a shared drink and redirects to a visible canonical detail' do
    sign_in user
    post cocktail_toggle_favorite_path(shared)
    expect(response).to redirect_to(cocktail_path(shared))
    follow_redirect!
    expect(response).to be_successful
    expect(response.body).to include('Remove favorite')
    post cocktail_toggle_favorite_path(foreign)
    expect(response).to have_http_status(:not_found)
  end

  it 'enforces canonical and legacy deletion rules even with forged scope parameters' do
    sign_in user
    delete cocktail_path(shared), as: :json
    expect(response).to have_http_status(:not_found)
    sign_in user
    delete shared_cocktail_path(shared), params: { deletion_scope: 'owned', id: owned.id }, as: :json
    expect(response).to have_http_status(:forbidden)
    sign_in admin
    post cocktail_delete_path(shared), params: { deletion_scope: 'shared' }, as: :json
    expect(response).to have_http_status(:not_found)
    sign_in admin
    delete cocktail_path(foreign), as: :json
    expect(response).to have_http_status(:not_found)
    sign_in admin
    delete shared_cocktail_path(shared), as: :json
    expect(response).to be_successful
    sign_in user
    post cocktail_delete_path(owned), as: :json
    expect(response.parsed_body).to include('action' => 'deleted', 'deleted_id' => owned.id)
  end

  it 'preserves copies and audit history when a master is deleted' do
    copy = create(:recipe, user: user, parent: shared)
    audit = create(:audit, user: user, recipe: shared)
    amount = create(:reagent_amount, recipe: shared)
    shared.cocktail_families << create(:cocktail_family)
    sign_in admin
    delete cocktail_path(shared)
    expect(response).to redirect_to(cocktails_path)
    expect(copy.reload.parent_id).to be_nil
    expect(audit.reload.recipe_id).to eq(shared.id)
    expect(audit.recipe).to be_nil
    expect(ReagentAmount.exists?(amount.id)).to be(false)
    expect(CocktailFamilyJoiner.where(recipe_id: shared.id)).to be_empty
  end

  it 'creates and edits personal recipes without accepting ownership changes' do
    create(:reagent_category, external_id: 'gin')
    allow(RecipeEmbeddingsService).to receive(:generate).and_return(nil)
    sign_in user
    payload = { cocktail: { name: 'New gin drink', user_id: nil, category: 'other', amounts: [{ amount: 1, unit: 'oz', tags: [{ tag: 'gin' }], optional: true }] } }
    post cocktails_path, params: payload, as: :json
    expect(response).to be_successful
    recipe = Recipe.find(response.parsed_body.fetch('cocktail_id'))
    expect(recipe).to have_attributes(user_id: user.id, category: 'cocktail')
    expect(recipe.ingredients.sole.reagent_amount_id).to eq(recipe.reagent_amounts.sole.id)
    payload[:cocktail][:name] = 'Edited gin drink'
    payload[:cocktail][:user_id] = foreign.user_id
    patch cocktail_path(recipe), params: payload, as: :json
    expect(response).to be_successful
    recipe = Recipe.find(recipe.id)
    expect(recipe).to have_attributes(name: 'Edited gin drink', user_id: user.id)
    expect(recipe.ingredients.sole.reagent_amount_id).to eq(recipe.reagent_amounts.sole.id)
  end

end
