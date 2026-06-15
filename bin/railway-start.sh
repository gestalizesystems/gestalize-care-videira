#!/bin/bash -e
# Start no Railway (serviço único, mais barato no trial).
# Roda migrations + seed (idempotente) e sobe Sidekiq + Puma no mesmo container.
# O ENTRYPOINT do Docker (jemalloc) continua sendo aplicado antes deste script.

bundle exec rails db:prepare
bundle exec rails db:seed

# Sidekiq em background (concorrência reduzida para economizar memória)
bundle exec sidekiq -C config/sidekiq.yml -c 2 &

# Puma como processo principal (escuta na porta definida em $PORT pelo Railway)
exec ./bin/rails server
