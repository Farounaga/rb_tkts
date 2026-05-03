FROM ruby:3.3-slim

WORKDIR /app

ARG TARGETARCH=amd64

# Dépendances Ruby + install binaire Ollama dans le même conteneur.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      gzip \
      libxml2-dev \
      libxslt1-dev \
      pkg-config \
      tar \
      zstd; \
    rm -rf /var/lib/apt/lists/*; \
    case "${TARGETARCH}" in \
      amd64|arm64) OLLAMA_ARCH="${TARGETARCH}" ;; \
      *) echo "Unsupported TARGETARCH for Ollama: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    curl --fail --show-error --location \
      "https://ollama.com/download/ollama-linux-${OLLAMA_ARCH}.tar.zst" \
      | zstd -d \
      | tar -xf - -C /usr/local; \
    test -x /usr/local/bin/ollama

COPY Gemfile Gemfile.lock ./
RUN bundle config set deployment 'true' \
  && bundle config set without 'development test' \
  && bundle install

COPY . .

CMD ["bundle", "exec", "ruby", "main.rb"]
