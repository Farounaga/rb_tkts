require_relative '../ollama_bootstrap'

RSpec.describe OllamaBootstrap do
  it 'resolves required models from explicit env list first' do
    allow(AppConfig).to receive(:ollama_models).and_return(%w[m1 m2])
    allow(AppConfig).to receive(:ollama_embed_model).and_return('embed')
    allow(AppConfig).to receive(:ollama_llm_model).and_return('llm')

    expect(OllamaBootstrap.required_models(need_llm: true, need_embeddings: true)).to eq(%w[m1 m2])
  end

  it 'falls back to embed/llm models when explicit list is empty' do
    allow(AppConfig).to receive(:ollama_models).and_return([])
    allow(AppConfig).to receive(:ollama_embed_model).and_return('embed')
    allow(AppConfig).to receive(:ollama_llm_model).and_return('llm')

    expect(OllamaBootstrap.required_models(need_llm: true, need_embeddings: true)).to eq(%w[embed llm])
    expect(OllamaBootstrap.required_models(need_llm: false, need_embeddings: true)).to eq(%w[embed])
  end

  it 'returns false when server is down and autostart is disabled' do
    allow(AppConfig).to receive(:ollama_base_url).and_return('http://localhost:11434')
    allow(AppConfig).to receive(:ollama_auto_start?).and_return(false)
    allow(OllamaBootstrap).to receive(:server_up?).and_return(false)

    expect(OllamaBootstrap.ensure_ready!(need_llm: true, need_embeddings: true)).to eq(false)
  end
end
