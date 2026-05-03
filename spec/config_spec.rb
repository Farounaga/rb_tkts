require_relative '../config'

RSpec.describe AppConfig do
  around do |example|
    backup = ENV.to_hash
    example.run
  ensure
    ENV.replace(backup)
  end

  it 'reads boolean run flags from env' do
    ENV['RUN_EMBEDDINGS'] = 'false'
    ENV['RUN_CLUSTER_TOPICS'] = 'false'
    ENV['RUN_EXPORT_CSV'] = 'false'

    expect(AppConfig.run_embeddings?).to eq(false)
    expect(AppConfig.run_cluster_topics?).to eq(false)
    expect(AppConfig.run_export_csv?).to eq(false)
  end

  it 'parses ollama model list from csv' do
    ENV['OLLAMA_MODELS'] = 'a, b ,a,,c'
    expect(AppConfig.ollama_models).to eq(%w[a b c])
  end

  it 'reads topic generation tuning defaults' do
    ENV.delete('TOPIC_NUM_PREDICT')
    ENV.delete('TOPIC_TEMPERATURE')

    expect(AppConfig.topic_num_predict).to eq(32)
    expect(AppConfig.topic_temperature).to eq(0.2)
  end

  it 'uses skip-ollama fallback by default' do
    ENV.delete('SKIP_OLLAMA_ON_ERROR')
    expect(AppConfig.skip_ollama_on_error?).to eq(true)
  end

  it 'reads embedding max chars with default fallback' do
    ENV.delete('EMBEDDING_MAX_CHARS')
    expect(AppConfig.embedding_max_chars).to eq(12_000)
  end

  it 'reads xml db defaults' do
    ENV.delete('XML_DB_ENABLED')
    ENV.delete('XML_DB_BASE_URL')
    ENV.delete('XML_DB_DATABASE')

    expect(AppConfig.xml_db_enabled?).to eq(false)
    expect(AppConfig.xml_db_base_url).to eq('http://xml-db:8984')
    expect(AppConfig.xml_db_database).to eq('ticketsdb')
  end
end
