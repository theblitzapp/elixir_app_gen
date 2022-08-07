defmodule AppGen.ConfigState.FileParser do
  def parse(config_file_path) do
    {resources, _} = Code.eval_file(config_file_path)

    List.flatten(resources)
  end
end
