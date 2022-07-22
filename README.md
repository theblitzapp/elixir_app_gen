# AppGen

This tool generates various parts of our elixir applications to simplify our workflows.

### Generators
- [x] Absinthe API & Tests
- [x] Ecto Schema
- [x] Ecto Context, Factories & Tests
- [ ] Phoenix Application++ (prometheus/sentry)
- [ ] Logic Nodes
- [ ] Logic Gateways

## Installation

Available in Hex, the package can be installed
by adding `app_gen` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:app_gen, "~> 0.1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/app_gen](https://hexdocs.pm/app_gen).

## Example
Checkout `app_gen.exs` for an example

## Available Mix Commands
```
mix app_gen          # Lists help for app_gen.gen. commands
mix app_gen.api      # Utilizes the config file and generates a GraphQL API
mix app_gen.resource # Creates a resource file that will be used to configure absinthe routes and can create schemas
```
