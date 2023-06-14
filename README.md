# AppGen

[![Build Status](https://github.com/theblitzapp/elixir_app_gen/workflows/Coveralls/badge.svg)](https://github.com/theblitzapp/elixir_app_gen)
[![Build Status](https://github.com/theblitzapp/elixir_app_gen/workflows/Dialyzer/badge.svg)](https://github.com/theblitzapp/elixir_app_gen)
[![Build Status](https://github.com/theblitzapp/elixir_app_gen/workflows/Credo/badge.svg)](https://github.com/theblitzapp/elixir_app_gen)
[![Build Status](https://github.com/theblitzapp/elixir_app_gen/workflows/Doctor/badge.svg)](https://github.com/theblitzapp/elixir_app_gen)
[![codecov](https://codecov.io/gh/theblitzapp/elixir_app_gen/branch/main/graph/badge.svg?token=P3O42SF7VJ)](https://codecov.io/gh/theblitzapp/elixir_app_gen)

This tool generates various parts of our elixir applications to simplify our workflows.

### Generators
- [x] Absinthe API & Tests
- [x] Ecto Schema
- [x] Ecto Context, Factories & Tests
- [x] State Diff and Regeneration
- [ ] Typespecs for all files
- [ ] Phoenix Application++ (prometheus/sentry)
  - [x] `no_phx` - Skip phx.new generation (back-add this to already generated project)
  - [x] `absinthe` - Pulls in absinthe dependency and sets it up in `router.ex` & `endpoint.ex`
  - [ ] `no_prometheus` - By default prometheus and exporter config will be setup with basic metrics
  - [ ] `no_sentry` - By default prometheus and exporter config will be setup with basic metrics
  - [ ] `no_libcluster` - By default libcluster setup will be installed and dependency imported
  - [ ] `no_config_mod` - By default a config.ex module will be installed to gatekeep access to app env config
  - [ ] `no_cors` - By default [Corsica](https://github.com/whatyouhide/corsica) is installed into the `endpoint.exs`
  - [ ] `no_log_hide` - By default we remove 200 logs to save log space in prod
- [ ] State Transitions
- [ ] Logic Nodes
- [ ] Logic Gateways

## Installation

Available in Hex, the package can be installed
by adding `app_gen` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:app_gen, "~> 0.1.0", only: [:dev, :test]}
  ]
end
```

The docs can be found at [https://hexdocs.pm/app_gen](https://hexdocs.pm/app_gen).

## Example
Checkout `app_gen.exs` for an example

## Available Mix Commands
```
mix app_gen          # Lists help for app_gen commands
mix app_gen.api      # Utilizes all the config files and generates a GraphQL API
mix app_gen.context  # Creates a ecto context with functions from EctoShorts as well as tests
mix app_gen.resource # Used to create app_gen.exs files or to add new CRUD resources in
mix app_gen.schema   # Creates a ecto schema that has a factory
mix app_gen.phx.new  # Create a new phx project, replaces `mix phx.new`
```
