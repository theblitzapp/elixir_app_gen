defmodule AppConfigTest do
  use ExUnit.Case
  doctest AppConfig

  test "greets the world" do
    assert AppConfig.hello() == :world
  end
end
