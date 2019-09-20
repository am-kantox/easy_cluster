defmodule EasyCluster.NodeInfo do
  @moduledoc """
  The struct that holds the parsed node info.
  """
  defstruct __meta__: %{},
            full: nil,
            host: nil,
            fq_name: nil,
            otp_app: nil,
            group: nil,
            local_id: nil

  @typedoc "The internal representation of node name, parsed"
  @type t :: %{
          optional(atom) => binary(),
          __struct__: atom(),
          __meta__: %{required(atom()) => boolean()}
        }

  @doc "Parses the node name and returns an instance of `EasyCluster.NodeInfo` back"
  @spec new!(node_name :: nil | atom() | binary()) :: t()
  def new!(node_name \\ nil)
  def new!(nil), do: new!(Node.self())

  def new!(node_name) when is_atom(node_name),
    do: node_name |> Atom.to_string() |> new!()

  def new!(node_name) when is_binary(node_name) do
    case String.split(node_name, "@") do
      [name, host] ->
        meta =
          case [name, host] do
            ["nonode", "nohost"] -> %{nonode: true, nohost: true, local: true}
            ["nonode", _] -> %{nonode: true}
            [_, "nohost"] -> %{nohost: true}
            [_, "localhost"] -> %{local: true}
            _ -> %{}
          end

        struct(__MODULE__, [
          {:__meta__, meta},
          {:full, node_name},
          {:host, host},
          {:fq_name, name} | parse_fq_name(name)
        ])

      name ->
        %EasyCluster.NodeInfo{__meta__: {:error, {:malformed_name, name}}}
    end
  end

  ##############################################################################

  @spec parse_fq_name(fq_name :: binary()) :: keyword()
  defp parse_fq_name(fq_name) do
    case String.split(fq_name, "_") do
      [otp_app] -> [otp_app: otp_app]
      [otp_app, local_id] -> [otp_app: otp_app, local_id: local_id]
      [otp_app, group, local_id] -> [otp_app: otp_app, group: group, local_id: local_id]
    end
  end
end
