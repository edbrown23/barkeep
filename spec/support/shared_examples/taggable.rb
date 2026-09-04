RSpec.shared_examples 'a taggable model' do |factory_name|
  let!(:gin_record) { create(factory_name, tags: ['gin']) }
  let!(:citrus_record) { create(factory_name, tags: ['lime', 'citrus']) }

  it 'finds records with any requested tag' do
    expect(described_class.with_tags(['gin', 'citrus'])).to contain_exactly(gin_record, citrus_record)
  end

  it 'excludes records without an overlapping tag' do
    expect(described_class.with_tags(['rum'])).to be_empty
  end

  it 'returns no records when no tags are requested' do
    expect(described_class.with_tags([])).to be_empty
  end
end
