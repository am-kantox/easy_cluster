defmodule EasyCluster.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    easy_cluster_config =
      Application.get_env(:easy_cluster, :easy_cluster,
        hosts: ["127.0.0.1"],
        groups: ["foo", "bar"],
        max_nodes: 10
      )

    children = [
      {EasyCluster.Default, [easy_cluster_config]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: EasyCluster.Supervisor)
  end
end
