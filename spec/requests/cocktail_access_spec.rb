require 'rails_helper'

RSpec.describe 'Cocktail access', type: :request do
  let(:owner) { create(:user) }
  let(:other) { create(:user) }
  let(:shared) { create(:recipe) }
  let(:owned) { create(:recipe, user: owner) }

  it 'renders shared details for guests without creating personal state' do
    shared
    expect { get cocktail_path(shared) }.not_to change(CocktailFamily, :count)
    expect(response).to be_successful
    expect(response.body).to include('Servings', 'Community notes')
    expect(response.body).not_to include('Your recent notes:', 'usersVersions')
  end

  it 'does not use ambient User.current for public visibility' do
    User.current_id = owner.id
    get cocktail_path(owned)
    expect(response).to have_http_status(:not_found)
    get cocktail_path(shared)
    expect(response).to be_successful
  end

  it 'allows shared and owned details but not another users recipe or a non-cocktail' do
    sign_in owner
    [shared, owned].each do |recipe|
      get cocktail_path(recipe)
      expect(response).to be_successful
    end
    [create(:recipe, user: other), create(:recipe, category: 'other')].each do |recipe|
      get cocktail_path(recipe)
      expect(response).to have_http_status(:not_found)
    end
  end

  it 'does not allow editing masters or another users recipes' do
    sign_in owner
    [shared, create(:recipe, user: other)].each do |recipe|
      sign_in owner
      get edit_cocktail_path(recipe)
      expect(response).to have_http_status(:not_found)
      sign_in owner
      patch cocktail_path(recipe), params: { cocktail: { name: 'Changed' } }, as: :json
      expect(response).to have_http_status(:not_found)
      expect(recipe.reload.name).not_to eq('Changed')
    end
  end

  it 'only displays global and viewer-owned families on a master' do
    shared.cocktail_families << create(:cocktail_family, name: 'Public family')
    shared.cocktail_families << create(:cocktail_family, user: owner, name: 'My family')
    shared.cocktail_families << create(:cocktail_family, user: other, name: 'Secret family')
    sign_in owner
    get cocktail_path(shared)
    expect(response.body).to include('Public family', 'My family')
    expect(response.body).not_to include('Secret family')
  end
end
