require 'csv'
require 'json'
require 'tmpdir'
require_relative '../export_csv'

RSpec.describe 'export_tickets_summary_csv' do
  it 'exporte un CSV lisible avec les données agrégées du pipeline' do
    Dir.mktmpdir do |dir|
      tickets = [
        {
          nice_id: '2001',
          subject: 'Accès compte bloqué',
          created_at: '2025-01-04T09:00:00Z',
          status_id: 'open',
          requester_id: '501',
          current_tags: 'partage,demo',
          comments: [{ value: 'a' }, { value: 'b' }]
        }
      ]

      clusters_file = File.join(dir, 'clusters.json')
      topics_file = File.join(dir, 'cluster_topics.json')
      similarity_file = File.join(dir, 'similar_tickets.json')
      metrics_file = File.join(dir, 'clustering_metrics.json')
      embeddings_file = File.join(dir, 'embeddings.json')
      output_file = File.join(dir, 'tickets_summary.csv')

      File.write(clusters_file, JSON.pretty_generate({ '2001' => 0 }))
      File.write(topics_file, JSON.pretty_generate({ '0' => 'Problème accès compte' }))
      File.write(
        similarity_file,
        JSON.pretty_generate(
          {
            '2001' => [
              { 'nice_id' => '2002', 'similarity' => 0.91, 'probable_duplicate' => true }
            ]
          }
        )
      )
      File.write(metrics_file, JSON.pretty_generate({ 'selected_k' => 3, 'silhouette_score' => 0.45, 'elbow' => [{ 'k' => 2, 'inertia' => 1.23 }] }))
      File.write(embeddings_file, JSON.pretty_generate([{ 'nice_id' => '2001', 'vector' => [0.1, 0.2, 0.3] }]))

      export_tickets_summary_csv(
        tickets,
        output_file,
        clusters_file: clusters_file,
        topics_file: topics_file,
        similarity_file: similarity_file,
        metrics_file: metrics_file,
        embeddings_file: embeddings_file
      )

      rows = CSV.read(output_file, headers: true, col_sep: ';')
      expect(rows.size).to eq(1)
      expect(rows[0]['nice_id']).to eq('2001')
      expect(rows[0]['cluster_topic']).to eq('Problème accès compte')
      expect(rows[0]['probable_duplicates_count']).to eq('1')
      expect(rows[0]['embedding_dim']).to eq('3')
    end
  end
end
