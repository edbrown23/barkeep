require 'rails_helper'

RSpec.describe CocktailCopyService do
  let(:user) { create(:user) }
  let(:source) { create(:recipe, description: 'Stir over ice') }
  let!(:amount) { create(:reagent_amount, recipe: source, tags: ['gin'], amount: 2, unit: 'oz', optional: true, description: 'A garnish') }

  it 'creates independent personal copies with new ingredient IDs and no history or families' do
    source.cocktail_families << create(:cocktail_family)
    create(:audit, recipe: source, user: user)
    copy = described_class.customize(source, user).reload
    expect(copy).to have_attributes(user_id: user.id, parent_id: source.id, description: source.description, proposed_to_be_shared: false)
    copied_amount = copy.reagent_amounts.sole
    expect(copied_amount).to have_attributes(user_id: user.id, tags: amount.tags, optional: true, description: amount.description)
    expect(copy.ingredients.sole.reagent_amount_id).to eq(copied_amount.id)
    expect(copied_amount.id).not_to eq(amount.id)
    expect(copy.cocktail_families).to be_empty
    expect(copy.audits).to be_empty
    copied_amount.update!(amount: 3)
    expect(amount.reload.amount).to eq(2)
    expect { described_class.customize(source, user) }.to change(Recipe, :count).by(1)
  end

  it 'publishes a separate master once and clears the proposal atomically' do
    source.update!(user: user, proposed_to_be_shared: true, proposer_user_id: user.id)
    copy = described_class.publish(source).reload
    expect(copy).to have_attributes(user_id: nil, parent_id: nil, proposed_to_be_shared: false, proposer_user_id: nil)
    expect(copy.reagent_amounts.sole.user_id).to be_nil
    expect(source.reload).to have_attributes(user_id: user.id, proposed_to_be_shared: false, proposer_user_id: nil)
    expect { described_class.publish(source) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'rolls back the copy and leaves the proposal pending on ingredient failure' do
    source.update!(user: user, proposed_to_be_shared: true)
    allow_any_instance_of(ReagentAmount).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
    expect { described_class.publish(source) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(Recipe.count).to eq(1)
    expect(source.reload.proposed_to_be_shared).to be(true)
  end
end
