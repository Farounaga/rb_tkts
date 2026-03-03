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

    expect(AppConfig.run_embeddings?).to eq(false)
    expect(AppConfig.run_cluster_topics?).to eq(false)
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
end
