defmodule EasyCluster.Default do
  @moduledoc """
  Default implementation of the `EasyCluster`. Logs nodes appearance.
  """
  use EasyCluster,
    node_up_handler: &EasyCluster.Default.handle_node_up/1,
    node_down_handler: &EasyCluster.Default.handle_node_down/1

  require Logger

  @doc false
  def handle_node_up(%EasyCluster.NodeInfo{} = node),
    do: Logger.info("[🕸️] Node is up: " <> node.fq_name)

  @doc false
  def handle_node_down(%EasyCluster.NodeInfo{} = node),
    do: Logger.info("[🕸️] Node is down: " <> node.fq_name)
end
