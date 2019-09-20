defmodule EasyCluster do
  @moduledoc """
  Looks up the nodes in the same cluster _and_ in the same group
  based on the configuration given.

  The configuration is specified as a keyword with `hosts` list, `groups` list
  and `max_nodes` integer.

  The application, using `EasyCluster` must have the module that is implementing
  `EasyCluster` behaviour, started in the supervision tree.
  """

  # @doc """
  # Returns a full node representation as a struct `EasyCluster.NodeInfo.t()`.
  # """
  # def node_info(node \\ nil), do: EasyCluster.NodeInfo.new!(node)

  @doc "The callback on another node in the cluster coming alive"
  @callback handle_node_up(source :: EasyCluster.NodeInfo.t(), node :: EasyCluster.NodeInfo.t()) ::
              :ok

  @doc "The callback on another node in the cluster coming dead"
  @callback handle_node_down(source :: EasyCluster.NodeInfo.t(), node :: EasyCluster.NodeInfo.t()) ::
              :ok

  defstruct config: nil, self: nil, group: nil, siblings: %{}

  @typedoc "The internal representation of the cluster _and_ group"
  @type t :: %{
          config: keyword(),
          self: EasyCluster.NodeInfo.t(),
          siblings: %{required(atom()) => EasyCluster.NodeInfo.t()},
          __struct__: atom()
        }

  require Logger

  defmacro __using__(opts \\ []) do
    quote location: :keep do
      @timeout 1_000

      ##########################################################################

      @behaviour EasyCluster

      @node_up_handler Keyword.get(unquote(opts), :node_up_handler, &EasyCluster.handle_node_up/2)
      @node_down_handler Keyword.get(
                           unquote(opts),
                           :node_down_handler,
                           &EasyCluster.handle_node_down/2
                         )

      @impl EasyCluster
      def handle_node_up(%EasyCluster.NodeInfo{} = source, %EasyCluster.NodeInfo{} = node),
        do: @node_up_handler.(source, node)

      @impl EasyCluster
      def handle_node_down(%EasyCluster.NodeInfo{} = source, %EasyCluster.NodeInfo{} = node),
        do: @node_down_handler.(source, node)

      ##########################################################################

      use GenServer

      def start_link(config),
        do: GenServer.start_link(__MODULE__, config, name: __MODULE__)

      def state, do: GenServer.call(__MODULE__, :state)

      @impl GenServer
      def init(config),
        do:
          {:ok, struct(EasyCluster, config: config, self: EasyCluster.NodeInfo.new!()),
           {:continue, :discover}}

      @impl GenServer
      def handle_continue(:discover, %EasyCluster{} = state),
        do: {:noreply, do_handle_discover(state)}

      @impl GenServer
      def handle_call(:state, _from, %EasyCluster{} = state), do: {:reply, state, state}

      @impl GenServer
      def handle_info(:discover, %EasyCluster{} = state),
        do: {:noreply, do_handle_discover(state)}

      @spec do_handle_discover(state :: EasyCluster.t()) :: :ok
      defp do_handle_discover(%EasyCluster{config: config, siblings: siblings} = state) do
        hosts = Keyword.get(config, :hosts, ["127.0.0.1"])
        groups = Keyword.get(config, :groups, ["foo", "bar"])
        max_nodes = Keyword.get(config, :max_nodes, 10)

        updated_siblings =
          for host <- hosts,
              group <- groups,
              node_num <- Enum.map(0..max_nodes, &to_string/1),
              reduce: siblings do
            acc ->
              node =
                [state.self.otp_app, group, node_num]
                |> Enum.join("_")
                |> Kernel.<>("@")
                |> Kernel.<>(host)
                |> String.to_atom()

              if Node.ping(node) == :pong do
                acc
                |> Map.get_and_update(node, fn
                  nil ->
                    node_info = EasyCluster.NodeInfo.new!(node)
                    handle_node_up(state.self, node_info)
                    {nil, node_info}

                  value ->
                    {value, value}
                end)
                |> elem(1)
              else
                acc
              end
          end

        for {node, info} <- siblings, is_nil(updated_siblings[node]) do
          handle_node_down(state.self, info)
        end

        Process.send_after(self(), :discover, Keyword.get(config, :timeout, @timeout))
        %EasyCluster{state | siblings: updated_siblings}
      end
    end
  end

  def handle_node_up(%EasyCluster.NodeInfo{fq_name: source}, %EasyCluster.NodeInfo{full: node}),
    do: Logger.info("[#{source}@ 🕸️] Node is up: " <> node)

  def handle_node_down(%EasyCluster.NodeInfo{fq_name: source}, %EasyCluster.NodeInfo{full: node}),
    do: Logger.info("[#{source}@ 🕸️] Node is down: " <> node)
end
