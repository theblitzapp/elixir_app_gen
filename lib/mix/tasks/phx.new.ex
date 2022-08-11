defmodule Mix.Tasks.AppGen.Phx.New do
  doc = case Code.fetch_docs(Mix.Tasks.Phx.New) do
    {_, _, _, _, %{"en" => doc}, _, _} -> String.replace(doc, "phx.new", "app_gen.phx.new")
    _ -> "Phoenix not istalled, please make sure you can run `mix phx.install` before using this command"
  end

  @shortdoc "Creates a prod ready phoenix app, can supply all the same parameters as mix phx.new"
  @moduledoc """
  ## Phoenix Docs
  #{doc}

  ## mix app_gen.phx.new

  This command has a few additional options and generates
  some extra stuff into the project that can be useful in a production
  application.

  ### Extra Options
  - [x] `no_phx` - Skip phx.new generation (back-add this to already generated project)
  - [x] `absinthe` - Pulls in absinthe dependency and sets it up in `router.ex` & `endpoint.ex`
  - [ ] `no_prometheus` - By default prometheus and exporter config will be setup with basic metrics
  - [ ] `no_sentry` - By default prometheus and exporter config will be setup with basic metrics
  - [ ] `no_libcluster` - By default libcluster setup will be installed and dependency imported
  - [ ] `no_config_mod` - By default a config.ex module will be installed to gatekeep access to app env config
  - [ ] `no_cors` - By default [Corsica](https://github.com/whatyouhide/corsica) is installed into the `endpoint.exs`
  - [ ] `no_log_hide` - By default we remove 200 logs to save log space in prod
  """

  use Mix.Task

  alias AppGen.ProjectGenerator.Phx

  @phx_switches [
    dev: :boolean, assets: :boolean, ecto: :boolean,
    app: :string, module: :string, web_module: :string,
    database: :string, binary_id: :boolean, html: :boolean,
    gettext: :boolean, umbrella: :boolean, verbose: :boolean,
    live: :boolean, dashboard: :boolean, install: :boolean,
    prefix: :string, mailer: :boolean
  ]

  @custom_switches [
    absinthe: :boolean, no_prometheus: :boolean,
    no_libcluster: :boolean, no_config_mod: :boolean,
    no_cors: :boolean, no_log_hide: :boolean, no_phx: :boolean
  ]

  def run([]) do
    Mix.Tasks.Help.run(["app_gen.phx.new"])
  end

  def run(args) do
    File.cd!("./apps")

    {opts, _} = OptionParser.parse!(args, switches: @custom_switches)
    {all_args, app} = OptionParser.parse!(args, switches: @phx_switches ++ @custom_switches)

    project_name = hd(app)

    custom_flags = @custom_switches
      |> Keyword.keys
      |> Enum.map(&"--#{String.replace(to_string(&1), "_", "-")}")

    unless all_args[:no_phx] do
      args = args |> Enum.reject(&(&1 in custom_flags)) |> Kernel.++(["--no-install"])

      Mix.Tasks.Phx.New.run(args)
    end

    if opts !== [] do
      File.cd!("./#{project_name}")
      Mix.shell().info([:green, "Moving into apps/#{project_name}"])

      add_extras_to_project(project_name, opts)

      File.cd!("../..")
      Mix.shell().info([:green, "\nMoving back to umbrella root"])
    end
  end

  defp add_extras_to_project(project_name, opts) do
    if opts[:absinthe] do
      create_user_socket(project_name)

      Phx.Absinthe.run(project_name, opts)
    end

    # unless opts[:no_prometheus] do
    #   Phx.Prometheus.run(project_name, opts)
    # end

    # unless opts[:no_libcluster] do
    #   Phx.Libcluster.run(project_name, opts)
    # end

    # unless opts[:no_config_mod] do
    #   Phx.ConfigModule.run(project_name, opts)
    # end

    # unless opts[:no_cors] do
    #   Phx.Cors.run(project_name, opts)
    # end

    # unless opts[:no_log_hide] do
    #   Phx.LogHide.run(project_name, opts)
    # end
  end

  defp create_user_socket(project_name) do
    Mix.shell(Mix.Shell.Quiet)
    Mix.shell().cmd("mix phx.gen.socket User")
    Mix.shell(Mix.Shell.IO)

    Mix.shell().info([:green, "* creating ", :reset, "lib/#{project_name}_web/channels/user_socket.ex"])
  end
end
