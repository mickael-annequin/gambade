#!/usr/bin/env bash
# Build steps run by Render at each deploy.
set -o errexit

bundle install
# Start from scratch: Render's build cache once served an old compiled CSS.
bin/rails assets:clobber
bin/rails assets:precompile
bin/rails assets:clean
bin/rails db:migrate
bin/rails db:seed
