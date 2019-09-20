defmodule EasyCluster.Default do
  @moduledoc """
  Default implementation of the `EasyCluster`. Logs nodes appearance.
  """
  use EasyCluster,
    node_up_handler: &EasyCluster.Default.Handlers.handle_node_up/2,
    node_down_handler: &EasyCluster.Default.Handlers.handle_node_down/2

  defmodule Handlers do
    require Logger

    @doc false
    def handle_node_up(%EasyCluster.NodeInfo{fq_name: source}, %EasyCluster.NodeInfo{full: node}),
      do: Logger.info("[#{source}@ 🕸️] Node is up: " <> node)

    @doc false
    def handle_node_down(%EasyCluster.NodeInfo{fq_name: source}, %EasyCluster.NodeInfo{full: node}),
        do: Logger.info("[#{source}@ 🕸️] Node is down: " <> node)
  end
end
