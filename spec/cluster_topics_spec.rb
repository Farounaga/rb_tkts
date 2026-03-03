require_relative '../cluster_topics'

RSpec.describe 'Cluster topic text cleanup' do
  it 'removes think blocks and noisy prefixes' do
    raw = "<think>internal</think> Titre : \"Problèmes de partage des carnets\""
    expect(clean_topic_title(raw)).to eq('Problèmes de partage des carnets')
  end

  it 'limits output to 10 words max' do
    long = 'un deux trois quatre cinq six sept huit neuf dix onze douze'
    expect(clean_topic_title(long).split.size).to eq(10)
  end
end
