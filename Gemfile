source "https://rubygems.org"

gem "rails", "~> 7.2.2"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "redis", ">= 4.0.1"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false

# Auth
gem "devise"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"

# Authorization & Audit
gem "pundit"
gem "paper_trail"

# Payments & Background
gem "sidekiq", "~> 7.0"
gem "sidekiq-cron"
gem "mercadopago", "~> 2.1"

# Image processing
gem "image_processing", "~> 1.2"

# Pagination
gem "pagy", "~> 8.0"

# Env vars
gem "dotenv-rails"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "web-console"
end

group :test do
  gem "shoulda-matchers"
  gem "webmock"
  gem "capybara"
end
