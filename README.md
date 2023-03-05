# Tucan

Tucan is a twitter-like web client for Nostr build using React.  It has a central server, written in Elixir, which aggregates events from many relays and pre-processes them.  The client requests events from the server via an API.

## Starting Tucan in development

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Building for production

To build the code for production run `bash build.sh`.  This will build the JS code and assets, compile the Elxir code to erlang bytecode and bundle the Erlang runtime system.  The result is a tar file containing all the dependencies to run Tucan on a production server.

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
