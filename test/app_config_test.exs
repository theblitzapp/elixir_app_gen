defmodule PhoenixConfigTest do
  use ExUnit.Case
  doctest PhoenixConfig

  test "greets the world" do
    assert PhoenixConfig.hello() == :world
  end
end
