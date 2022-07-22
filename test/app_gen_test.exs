defmodule AppGenTest do
  use ExUnit.Case
  doctest AppGen

  test "greets the world" do
    assert AppGen.hello() == :world
  end
end
