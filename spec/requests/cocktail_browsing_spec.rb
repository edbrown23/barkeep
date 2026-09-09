require 'rails_helper'

RSpec.describe 'Cocktail browsing', type: :request do
  let(:user) { create(:user) }
  let!(:shared) { create(:recipe, name: 'Public martini') }
  let!(:owned) { create(:recipe, user: user, name: 'Personal martini', proposed_to_be_shared: true) }
  let!(:foreign) { create(:recipe, user: create(:user), name: 'Private secret') }

  it 'renders one index with guest-safe controls and canonical links' do
    get cocktails_path
    expect(response).to be_successful
    expect(response.body).to include('Public martini', "href=\"#{cocktail_path(shared)}\"")
    expect(response.body).not_to include('Personal martini', 'Private secret', 'New Cocktail', 'id="ownership"', 'id="makeable"', 'cocktailProposalsTable')
    sign_in user
    get cocktails_path
    expect(response).to be_successful
    expect(response.body).to include('Personal martini', 'id="ownership"', 'id="makeable"')
    expect(response.body).not_to include('Private secret')
  end

  it 'preserves filters on old index links and sends shared detail links to the canonical page' do
    get shared_cocktails_path, params: { ownership: 'mine', search_term: 'martini', search_tags: ['gin'], makeable: 'on', page: 2 }
    expect(response).to have_http_status(:found)
    query = Rack::Utils.parse_nested_query(URI(response.location).query)
    expect(query).to include('ownership' => 'shared', 'search_term' => 'martini', 'search_tags' => ['gin'], 'makeable' => 'on', 'page' => '2')
    get shared_cocktail_path(shared)
    expect(response).to redirect_to(cocktail_path(shared))
    follow_redirect!
    expect(response).to be_successful
    get shared_cocktail_path(foreign)
    follow_redirect!
    expect(response).to have_http_status(:not_found)
  end

  it 'shows proposals only to admins in the shared view' do
    sign_in user
    get cocktails_path(ownership: 'shared')
    expect(response.body).not_to include('cocktailProposalsTable', 'Personal martini')
    sign_in create(:user, roles: ['admin'])
    get cocktails_path(ownership: 'shared')
    expect(response).to be_successful
    expect(response.body).to include('cocktailProposalsTable', 'Personal martini', 'Publish shared recipe')
  end

  it 'scopes linked family pages and their recipes to the viewer' do
    family = create(:cocktail_family)
    family.recipes << [shared, owned, foreign]
    sign_in user
    get cocktail_family_path(family)
    expect(response).to be_successful
    expect(response.body).to include('Public martini', 'Personal martini')
    expect(response.body).not_to include('Private secret')
    get cocktail_family_path(create(:cocktail_family, user: foreign.user))
    expect(response).to have_http_status(:not_found)
  end
end
