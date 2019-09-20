defmodule EasyCluster.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {EasyCluster.Default, [Application.fetch_env!(:easy_cluster, :easy_cluster)]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: EasyCluster.Supervisor)
  end
end
