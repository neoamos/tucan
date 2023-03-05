# Get Elixir deps
mix deps.get --only prod
MIX_ENV=prod mix compile

# Compile assets
mix phx.digest.clean --all
MIX_ENV=prod mix assets.deploy

# Generate release
MIX_ENV=prod mix release

# Tar release
tar -zcvf nostr.tar.gz -C _build/prod/rel/app/ .