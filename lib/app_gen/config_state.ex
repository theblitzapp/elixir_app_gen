defmodule AppGen.ConfigState do
  alias AppGen.ConfigState.{FileParser, Expander}

  def parse_and_expand(config_file_path) do
    config_file_path
      |> FileParser.parse
      |> Expander.expand
  end
end
