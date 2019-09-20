import Config

config :easy_cluster, :easy_cluster,
  hosts: ["127.0.0.1"],
  groups: ["foo", "bar"],
  max_nodes: 10
