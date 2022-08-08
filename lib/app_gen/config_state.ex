defmodule AppGen.ConfigState do
  alias AppGen.ConfigState.{FileParser, Expander, Saver}

  def parse_and_expand(config_file_path) do
    config_file_path
      |> FileParser.parse
      |> Expander.expand
  end

  def diff_and_save(generator_structs) do
    if Saver.state_exists?() do
      diff_structs = generator_structs -- Saver.read_from_file()

      Saver.save(generator_structs)

      diff_structs
    else
      Saver.save(generator_structs)
    end
  end
end
