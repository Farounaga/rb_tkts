require 'json'
require 'tmpdir'
require 'fileutils'
require_relative '../clustering_metrics'

RSpec.describe 'evaluate_clustering_metrics' do
  it 'génère un rapport cohérent à partir d’un dataset connu' do
    Dir.mktmpdir do |dir|
      input = File.join(dir, 'embeddings.json')
      output = File.join(dir, 'clustering_metrics.json')

      embeddings = [
        { 'nice_id' => '1', 'vector' => [0.0, 0.0] },
        { 'nice_id' => '2', 'vector' => [0.1, 0.1] },
        { 'nice_id' => '3', 'vector' => [5.0, 5.0] },
        { 'nice_id' => '4', 'vector' => [5.1, 5.1] }
      ]

      File.write(input, JSON.pretty_generate(embeddings))
      report = evaluate_clustering_metrics(input, output, k_min: 2, k_max: 4)

      expect(File.exist?(output)).to eq(true)
      expect(report).to include(:selected_k, :silhouette_score, :elbow)
      expect(report[:elbow]).not_to be_empty
      expect(report[:silhouette_score]).to be_between(-1.0, 1.0)
    end
  end
end
