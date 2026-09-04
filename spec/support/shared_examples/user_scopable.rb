RSpec.shared_examples 'a user-scoped model' do |factory_name, supports_shared: true|
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:owned_record) { create(factory_name, user: owner) }
  let!(:other_record) { create(factory_name, user: other_user) }
  let!(:shared_record) { create(factory_name, user: nil) } if supports_shared

  it 'selects records for an explicit user' do
    expect(described_class.for_user(owner)).to contain_exactly(owned_record)
  end

  it 'falls back to the current user' do
    User.current_id = owner.id

    expect(described_class.for_user).to contain_exactly(owned_record)
  end

  it 'returns the records available to the user from the shared scope' do
    expected_records = supports_shared ? [owned_record, shared_record] : [owned_record]

    expect(described_class.for_user_or_shared(owner)).to contain_exactly(*expected_records)
  end

  it 'does not include another user records' do
    expect(described_class.for_user_or_shared(owner)).not_to include(other_record)
  end
end
