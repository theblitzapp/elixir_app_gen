defmodule AppGen.ProjectGenerator.Phx.Absinthe do
  alias AppGen.ProjectGenerator

  @absinthe_version "~> 1.7"
  @absinthe_plug_version "~> 1.5"
  @absinthe_phx_version "~> 2.0"

  @test_schema """
  defmodule <MY_APP>Web.Schema do
    @moduledoc "GraphQL Schema File"

    use Absinthe.Schema

    query do
      field :hello_world, :string do
        resolve fn _, _ -> {:ok, "Hello World"} end
      end
    end
  end
  """

  def run(project_name, _opts) do
    ProjectGenerator.inject_into_file!(
      "mix.exs",
      "absinthe",
      &add_absinthe_to_mix_exs/1
    )

    ProjectGenerator.inject_into_file!(
    "./lib/#{project_name}_web/endpoint.ex",
      "absinthe",
      &(&1 |> add_absinthe_to_endpoint_ex |> add_socket_to_endpoint_ex(project_name))
    )

    ProjectGenerator.inject_into_file!(
      "./lib/#{project_name}_web/router.ex",
      "absinthe",
      &add_absinthe_to_router_ex(project_name, &1)
    )

    ProjectGenerator.inject_into_file!(
      "./lib/#{project_name}/application.ex",
      "absinthe",
      &add_absinthe_to_application_ex(project_name, &1)
    )

    schema_path = "./lib/#{project_name}_web/schema.ex"
    example_schema = String.replace(@test_schema, "<MY_APP>", Macro.camelize(project_name))

    File.write!(schema_path, example_schema)
    IO.puts(IO.ANSI.format([:green, "* creating ", :reset, schema_path, :reset]))
  end

  defp add_absinthe_to_mix_exs(mix_exs_contents) do
    original = "defp deps do\n    [\n"
    replacement = "defp deps do\n    [\n      {:absinthe, \"#{@absinthe_version}\"},"
    replacement = replacement <> "\n      {:absinthe_plug, \"#{@absinthe_plug_version}\"},"
    replacement = replacement <> "\n      {:absinthe_phoenix, \"#{@absinthe_phx_version}\"},\n\n"

    mix_exs_contents
      |> String.replace(original, replacement)
      |> Code.format_string!
  end

  defp add_absinthe_to_router_ex(project_name, router_ex_contents) do
    original = "\n  scope \"/api\", #{Macro.camelize(project_name)}Web do\n"
    replacement = """
    pipeline :graphql do

    end

    scope "/graphql" do
      pipe_through [:api, :graphql]

      forward "/", Absinthe.Plug,
        schema: #{Macro.camelize(project_name)}Web.Schema,
        analyze_complexity: true
    end

    scope "/graphiql" do
      pipe_through [:api, :graphql]

      forward "/", Absinthe.Plug.GraphiQL,
        schema: #{Macro.camelize(project_name)}Web.Schema,
        socket: #{Macro.camelize(project_name)}Web.Socket
    end
    """

    router_ex_contents
      |> String.replace(original, replacement <> original)
      |> Code.format_string!
  end

  defp add_absinthe_to_application_ex(project_name, application_ex_contents) do
    original = "#{Macro.camelize(project_name)}Web.Endpoint,"
    replacement = """
    #{original}
    {Absinthe.Subscription, #{Macro.camelize(project_name)}Web.Endpoint},
    """

    application_ex_contents
      |> String.replace(original, replacement)
      |> Code.format_string!
  end

  defp add_absinthe_to_endpoint_ex(endpoint_ex_contents) do
    original = ~r/defmodule ([\w \.]+)\n  use Phoenix.Endpoint, otp_app: :([a-z_]+)\n/
    replacement = """
    defmodule \\1
      use Phoenix.Endpoint, otp_app: :\\2
      use Absinthe.Phoenix.Endpoint
    """

    endpoint_ex_contents
      |> String.replace(original, replacement)
      |> Code.format_string!
      |> to_string
  end

  defp add_socket_to_endpoint_ex(endpoint_ex_contents, project_name) do
    original = "\n  socket"
    replacement = """

    socket "/socket", #{Macro.camelize(project_name)}Web.UserSocket,
      websocket: true,
      longpoll: false
    """ <> original

    endpoint_ex_contents
      |> String.replace(original, replacement)
      |> Code.format_string!
  end
end
