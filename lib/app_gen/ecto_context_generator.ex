defmodule AppGen.EctoContextGenerator do
  @moduledoc false

  def context_path(context_module) do
    context_app_module = Mix.Phoenix.context_app()
      |> to_string
      |> Macro.camelize

    context_module = String.replace(context_module, ~r/^#{context_app_module}\./i, "")

    Mix.Phoenix.context_lib_path(
      Mix.Phoenix.context_app(),
      "#{Macro.underscore(context_module)}.ex"
    )
  end

  def context_module(schema) when is_atom(schema) do
    context_module(inspect(schema))
  end

  def context_module(schema) when is_binary(schema) do
    schema
      |> String.split(".")
      |> Enum.drop(-1)
      |> Enum.join(".")
  end

  def create_context_module_for_schemas(repo, context_module, schemas) do
    context_module_string = to_module_string(context_module)

    Code.format_string!("""
    defmodule #{context_module_string} do
      alias EctoShorts.Actions

      #{schemas |> Enum.map(&"alias #{inspect(&1)}") |> Enum.join("\n")}

      #{maybe_repo_module_attribute(repo)}

      #{schemas |> Enum.map(&create_ecto_shorts_crud_functions(&1, repo)) |> Enum.join("\n")}
    end
    """)
  end

  defp maybe_repo_module_attribute(nil), do: ""
  defp maybe_repo_module_attribute(repo) do
    repo_name = repo_underscore_name(repo)

    if repo_name === "repo" do
      "@repo [repo: #{repo}]"
    else
      "@#{repo_name}_repo [repo: #{repo}]"
    end
  end

  defp create_ecto_shorts_crud_functions(schema, repo) when is_atom(schema) do
    create_ecto_shorts_crud_functions(inspect(schemas), repo)
  end

  defp create_ecto_shorts_crud_functions(schema, repo) do
    schema_module = schema |> Macro.camelize |> String.split(".") |> List.last
    schema_name = Macro.underscore(schema_module)
    repo_opt = case repo_underscore_name(repo) do
      "repo" -> ", @repo"
      nil -> ""
      repo -> ", @#{repo}_repo"
    end

    """
      @spec create_#{schema_name}(map) :: EctoShorts.Actions.schema_res()
      def create_#{schema_name}(params) do
        Actions.create(#{schema_module}, params#{repo_opt})
      end

      @spec find_#{schema_name}(map) :: EctoShorts.Actions.schema_res()
      def find_#{schema_name}(params) do
        Actions.find(#{schema_module}, params#{repo_opt})
      end

      @spec all_#{Inflex.pluralize(to_string(schema_name))}(map) :: list(EctoSchema.t()) | {:error, ErrorMessage.t()}
      def all_#{Inflex.pluralize(to_string(schema_name))}(params #{"\\"}#{"\\"} %{}) do
        Actions.all(#{schema_module}, params#{repo_opt})
      end

      @spec update_#{schema_name}(pos_integer() || String.t() || Ecto.Schema.t(), map) :: EctoShorts.Actions.schema_res()
      def update_#{schema_name}(id_or_schema, params) do
        Actions.update(#{schema_module}, id_or_schema, params#{repo_opt})
      end

      @spec delete_#{schema_name}(pos_integer() || String.t() || Ecto.Schema.t()) :: EctoShorts.Actions.schema_res()
      def delete_#{schema_name}(id_or_schema) do
        Actions.delete(#{schema_module}, id_or_schema#{repo_opt})
      end

      @spec find_and_upsert_#{schema_name}(map, map) :: EctoShorts.Actions.schema_res()
      def find_and_upsert_#{schema_name}(find_params, update_params) do
        Actions.find_and_upsert(#{schema_module}, find_params, update_params#{repo_opt})
      end
    """
  end

  defp repo_underscore_name(repo) do
    repo |> String.split(".") |> List.last |> Macro.underscore
  end

  def to_module_string(any) do
    any |> to_string |> Macro.camelize
  end
end
