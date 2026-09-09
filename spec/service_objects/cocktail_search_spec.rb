require 'rails_helper'

RSpec.describe CocktailSearch do
  let(:user) { create(:user) }
  let!(:shared) { create(:recipe, name: "Gin $$ ' special", ingredients_blob: { ingredients: [{ tags: ['gin'], amount: 1, unit: 'oz' }] }) }
  let!(:owned) { create(:recipe, user: user) }
  let!(:foreign) { create(:recipe, user: create(:user)) }
  let!(:ephemeral) { create(:recipe, user: user, source: 'drink_builder') }

  def search(viewer = user, **params)
    described_class.new(viewer, params)
  end

  it 'isolates public and signed-in browsing, excluding ephemeral recipes' do
    User.current_id = user.id
    expect(search(nil, ownership: 'mine', makeable: 'on').results).to contain_exactly(shared)
    expect(search.results).to contain_exactly(shared, owned)
    expect(search(ownership: 'mine').results).to contain_exactly(owned)
    expect(search(ownership: 'shared').results).to contain_exactly(shared)
    expect(search(ownership: 'invalid').results).to contain_exactly(shared, owned)
  end

  it 'translates legacy ownership filters without broadening conflicting filters' do
    expect(search(user_recipes_only: 'on').results).to contain_exactly(owned)
    expect(search(shared_recipes_only: 'on').results).to contain_exactly(shared)
    expect(search(user_recipes_only: 'on', shared_recipes_only: 'on').results).to be_empty
  end

  it 'quotes the facet query even when the search contains SQL delimiters' do
    query = search(search_term: "$$ '")
    expect(query.results).to contain_exactly(shared)
    expect(query.facets.keys).to include('gin')
    expect(search(search_term: "'; DROP TABLE recipes; --").facets).to eq({})
    expect(Recipe.exists?(shared.id)).to be(true)
  end

  it 'uses OR family matching without duplicate results or foreign families' do
    families = [create(:cocktail_family), create(:cocktail_family, user: user)]
    shared.cocktail_families << families
    private_family = create(:cocktail_family, user: foreign.user)
    owned.cocktail_families << private_family
    expect(search(family_ids: families.map(&:id)).results).to contain_exactly(shared)
    expect(search(family_ids: [private_family.id]).results).to be_empty
    expect(search.families).to contain_exactly(*families)
  end

  it 'combines tag/name/makeable filtering and handles empty results' do
    create(:reagent, user: user, tags: ['gin'], current_volume_value: 2, current_volume_unit: 'oz')
    expect(search(search_tags: ['gin'], search_term: 'Gin', makeable: 'on').results).to contain_exactly(shared)
    expect(search(search_tags: ['gin', 'rum']).results).to be_empty
    expect(search(search_term: 'nonexistent').facets).to eq({})
  end
end
