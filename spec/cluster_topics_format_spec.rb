require_relative '../cluster_topics'

RSpec.describe 'Cluster topic formatting edge-cases' do
  it 'removes leading cluster prefix and quotes' do
    raw = "Cluster 4: \"Partage des carnets de vaccination\""
    expect(clean_topic_title(raw)).to eq('Partage des carnets de vaccination')
  end

  it 'keeps only the first sentence' do
    raw = "Problème rappel vaccinal. Détails supplémentaires inutiles."
    expect(clean_topic_title(raw)).to eq('Problème rappel vaccinal')
  end

  it 'returns nil for blank noisy answers' do
    raw = "<think>nothing</think>   "
    expect(clean_topic_title(raw)).to be_nil
  end

  it 'normalizes word count helper safely' do
    expect(normalize_topic_words(nil)).to be_nil
    expect(normalize_topic_words('')).to be_nil
    expect(normalize_topic_words('un deux trois', max_words: 2)).to eq('un deux')
  end
end
