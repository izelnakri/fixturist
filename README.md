# Fixturist

Fixturist fixes the major caveat of fixture based backend testing: your fixture records might have foreign-key constraints. This can prevent the insertion of your fixture records and you have to keep track of the order of relationships during the insertion.

This library checks if your records have relationships, fetches the required relationships from your development database and runs a nifty algorithm to order the insertion of fetched records. All happens with the minimal/optimized SQL under the hood.

**Fixturist only loads on test mix environments**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `fixturastic` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:fixturist, "~> 0.1.0"}]
    end
    ```

  2. Ensure `fixturastic` is started before your application:

    ```elixir
    def application do
      [applications: [:fixturist]]
    end
    ```

## Usage
todo
