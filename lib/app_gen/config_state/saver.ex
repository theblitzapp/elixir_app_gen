defmodule AppGen.ConfigState.Saver do
  @compression_level 9
  @state_file "./.app_gen.state"

  def save(generator_structs) do
    data = :erlang.term_to_binary(generator_structs, compressed: @compression_level)

    File.write!(@state_file, data)

    generator_structs
  end

  def state_exists? do
    File.exists?(@state_file)
  end

  def read_from_file do
    @state_file
    |> File.read!()
    |> :erlang.binary_to_term()
  end
end
