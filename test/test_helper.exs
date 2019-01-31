## The contents of this file are subject to the Mozilla Public License
## Version 1.1 (the "License"); you may not use this file except in
## compliance with the License. You may obtain a copy of the License
## at http://www.mozilla.org/MPL/
##
## Software distributed under the License is distributed on an "AS IS"
## basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
## the License for the specific language governing rights and
## limitations under the License.
##
## The Original Code is RabbitMQ.
##
## The Initial Developer of the Original Code is GoPivotal, Inc.
## Copyright (c) 2007-2019 Pivotal Software, Inc.  All rights reserved.


ExUnit.start()

defmodule TestHelper do
  import ExUnit.Assertions
  alias RabbitMQ.CLI.Plugins.Helpers, as: PluginHelpers
  alias RabbitMQ.CLI.Core.{CommandModules, Config, Helpers, NodeName}

  def get_rabbit_hostname(node_name_type \\ :shortnames) do
    Helpers.get_rabbit_hostname(node_name_type)
  end

  def hostname, do: NodeName.hostname()

  def domain, do: NodeName.domain()

  def fixture_file_path(filename) do
    Path.join([File.cwd!(), "test", "fixtures", "files", filename])
  end

  def fixture_plugins_path(plugins_directory) do
    Path.join([File.cwd!(), "test", "fixtures", "plugins", plugins_directory])
  end

  def get_cluster_name() do
    :rpc.call(get_rabbit_hostname(), :rabbit_nodes, :cluster_name, [])
  end

  def add_vhost(name) do
    :rpc.call(get_rabbit_hostname(), :rabbit_vhost, :add, [name, "acting-user"])
  end

  def delete_vhost(name) do
    # some quick tests create and delete a vhost immediately, resulting
    # in a high enough restart intensity in rabbit_vhost_sup_wrapper to
    # make the rabbit app terminate. See https://github.com/rabbitmq/rabbitmq-server/issues/1280.
    :timer.sleep(250)
    :rpc.call(get_rabbit_hostname(), :rabbit_vhost, :delete, [name, "acting-user"])
  end

  def list_vhosts() do
    :rpc.call(get_rabbit_hostname(), :rabbit_vhost, :info_all, [])
  end

  def enable_feature_flag(feature_flag) do
    :rpc.call(get_rabbit_hostname(), :rabbit_feature_flags, :enable, [feature_flag])
  end

  def list_feature_flags(arg) do
    :rpc.call(get_rabbit_hostname(), :rabbit_feature_flags, :list, [arg])
  end

  def add_user(name, password) do
    :rpc.call(get_rabbit_hostname(), :rabbit_auth_backend_internal, :add_user,
      [name, password, "acting-user"])
  end

  def delete_user(name) do
    :rpc.call(get_rabbit_hostname(), :rabbit_auth_backend_internal, :delete_user,
      [name, "acting-user"])
  end

  def list_users() do
    :rpc.call(get_rabbit_hostname(), :rabbit_auth_backend_internal, :list_users, [])
  end

  def trace_on(vhost) do
    :rpc.call(get_rabbit_hostname(), :rabbit_trace, :start, [vhost])
  end

  def trace_off(vhost) do
    :rpc.call(get_rabbit_hostname(), :rabbit_trace, :stop, [vhost])
  end

  def set_user_tags(name, tags) do
    :rpc.call(get_rabbit_hostname(), :rabbit_auth_backend_internal, :set_tags,
      [name, tags, "acting-user"])
  end

  def authenticate_user(name, password) do
    :rpc.call(get_rabbit_hostname(), :rabbit_access_control,:check_user_pass_login, [name, password])
  end

  def set_parameter(vhost, component_name, key, value) do
    :ok = :rpc.call(get_rabbit_hostname(), :rabbit_runtime_parameters, :parse_set, [vhost, component_name, key, value, :nouser])
  end

  def clear_parameter(vhost, component_name, key) do
    :rpc.call(get_rabbit_hostname(), :rabbit_runtime_parameters, :clear, [vhost, component_name, key, <<"acting-user">>])
  end

  def list_parameters(vhost) do
    :rpc.call(get_rabbit_hostname(), :rabbit_runtime_parameters, :list_formatted, [vhost])
  end

  def set_global_parameter(key, value) do
    :ok = :rpc.call(get_rabbit_hostname(), :rabbit_runtime_parameters, :parse_set_global,
      [key, value, "acting-user"])
  end

  def clear_global_parameter(key) do
    :rpc.call(get_rabbit_hostname(), :rabbit_runtime_parameters, :clear_global,
      [key, "acting-user"])
  end

  def list_global_parameters() do
    :rpc.call(get_rabbit_hostname(), :rabbit_runtime_parameters, :list_global_formatted, [])
  end

  def set_permissions(user, vhost, [conf, write, read]) do
    :rpc.call(get_rabbit_hostname(), :rabbit_auth_backend_internal, :set_permissions, [user, vhost, conf, write, read, "acting-user"])
  end

  def list_policies(vhost) do
    :rpc.call(get_rabbit_hostname(), :rabbit_policy, :list_formatted, [vhost])
  end

  def set_policy(vhost, name, pattern, value) do
    {:ok, decoded} = :rabbit_json.try_decode(value)
    parsed = :maps.to_list(decoded)
    :ok = :rpc.call(get_rabbit_hostname(), :rabbit_policy, :set, [vhost, name, pattern, parsed, 0, "all", "acting-user"])
  end

  def clear_policy(vhost, key) do
    :rpc.call(get_rabbit_hostname(), :rabbit_policy, :delete, [vhost, key, "acting-user"])
  end

  def list_operator_policies(vhost) do
    :rpc.call(get_rabbit_hostname(), :rabbit_policy, :list_formatted_op, [vhost])
  end

  def set_operator_policy(vhost, name, pattern, value) do
    {:ok, decoded} = :rabbit_json.try_decode(value)
    parsed = :maps.to_list(decoded)
    :ok = :rpc.call(get_rabbit_hostname(), :rabbit_policy, :set_op, [vhost, name, pattern, parsed, 0, "all", "acting-user"])
  end

  def clear_operator_policy(vhost, key) do
    :rpc.call(get_rabbit_hostname(), :rabbit_policy, :delete_op, [vhost, key, "acting-user"])
  end

  def declare_queue(name, vhost, durable \\ false, auto_delete \\ false, args \\ [], owner \\ :none) do
    queue_name = :rabbit_misc.r(vhost, :queue, name)
    :rpc.call(get_rabbit_hostname(),
              :rabbit_amqqueue, :declare,
              [queue_name, durable, auto_delete, args, owner, "acting-user"])
  end

  def delete_queue(name, vhost) do
    queue_name = :rabbit_misc.r(vhost, :queue, name)
    :rpc.call(get_rabbit_hostname(),
              :rabbit_amqqueue, :delete,
              [queue_name, false, false, "acting-user"])
  end

  def lookup_queue(name, vhost) do
    queue_name = :rabbit_misc.r(vhost, :queue, name)
    :rpc.call(get_rabbit_hostname(),
              :rabbit_amqqueue, :lookup,
              [queue_name])
  end

  def declare_exchange(name, vhost, type \\ :direct, durable \\ false, auto_delete \\ false, internal \\ false, args \\ []) do
    exchange_name = :rabbit_misc.r(vhost, :exchange, name)
    :rpc.call(get_rabbit_hostname(),
              :rabbit_exchange, :declare,
              [exchange_name, type, durable, auto_delete, internal, args, "acting-user"])
  end

  def list_permissions(vhost) do
    :rpc.call(
      get_rabbit_hostname(),
      :rabbit_auth_backend_internal,
      :list_vhost_permissions,
      [vhost],
      :infinity
    )
  end

  def set_topic_permissions(user, vhost, exchange, writePerm, readPerm) do
    :rpc.call(
        get_rabbit_hostname(),
        :rabbit_auth_backend_internal,
        :set_topic_permissions,
        [user, vhost, exchange, writePerm, readPerm, "acting-user"],
        :infinity
    )
  end

  def list_user_topic_permissions(user) do
    :rpc.call(
      get_rabbit_hostname(),
      :rabbit_auth_backend_internal,
      :list_user_topic_permissions,
      [user],
      :infinity
    )
  end

  def clear_topic_permissions(user, vhost) do
      :rpc.call(
        get_rabbit_hostname(),
        :rabbit_auth_backend_internal,
        :clear_topic_permissions,
        [user, vhost, "acting-user"],
        :infinity
      )
    end

  def set_vm_memory_high_watermark(limit) do
    :rpc.call(get_rabbit_hostname(), :vm_memory_monitor, :set_vm_memory_high_watermark, [limit])
  end

  def set_disk_free_limit(limit) do
    :rpc.call(get_rabbit_hostname(), :rabbit_disk_monitor, :set_disk_free_limit, [limit])
  end


  #
  # App lifecycle
  #

  def await_rabbitmq_startup() do
    :ok = :rabbit_misc.rpc_call(get_rabbit_hostname(), :rabbit, :await_startup, [])
  end

  def is_rabbitmq_app_running() do
    :rabbit_misc.rpc_call(get_rabbit_hostname(), :rabbit, :is_booted, [])
  end

  def start_rabbitmq_app do
    :rabbit_misc.rpc_call(get_rabbit_hostname(), :rabbit, :start, [])
    await_rabbitmq_startup()
    :timer.sleep(250)
  end

  def stop_rabbitmq_app do
    :rabbit_misc.rpc_call(get_rabbit_hostname(), :rabbit, :stop, [])
    :timer.sleep(1200)
  end

  def status do
    :rpc.call(get_rabbit_hostname(), :rabbit, :status, [])
  end



  def error_check(cmd_line, code) do
    assert catch_exit(RabbitMQCtl.main(cmd_line)) == {:shutdown, code}
  end

  def with_channel(vhost, fun) do
    with_connection(vhost,
      fn(conn) ->
        {:ok, chan} = AMQP.Channel.open(conn)
        AMQP.Confirm.select(chan)
        fun.(chan)
      end)
  end

  def with_connection(vhost, fun) do
    {:ok, conn} = AMQP.Connection.open(virtual_host: vhost)
    ExUnit.Callbacks.on_exit(fn ->
      try do
        :amqp_connection.close(conn, 1000)
      catch
        :exit, _ -> :ok
      end
    end)
    fun.(conn)
  end

  def with_connections(vhosts, fun) do
    conns = for v <- vhosts do
      {:ok, conn} = AMQP.Connection.open(virtual_host: v)
      conn
    end
    ExUnit.Callbacks.on_exit(fn ->
      try do
        for c <- conns, do: :amqp_connection.close(c, 1000)
      catch
        :exit, _ -> :ok
      end
    end)
    fun.(conns)
  end

  def message_count(vhost, queue_name) do
    with_channel(vhost, fn(channel) ->
      {:ok, %{message_count: mc}} = AMQP.Queue.declare(channel, queue_name)
      mc
    end)
  end

  def publish_messages(vhost, queue_name, count) do
    with_channel(vhost, fn(channel) ->
      AMQP.Queue.purge(channel, queue_name)
      for i <- 1..count do
        AMQP.Basic.publish(channel, "", queue_name,
                           "test_message" <> Integer.to_string(i))
      end
      AMQP.Confirm.wait_for_confirms(channel, 30)
    end)
  end

  def close_all_connections(node) do
    # we intentionally use connections_local/0 here because connections/0,
    # the cluster-wide version, loads some bits around cluster membership
    # that are not normally ready with a single node. MK.
    #
    # when/if we decide to test
    # this project against a cluster of nodes this will need revisiting. MK.
    for pid <- :rpc.call(node, :rabbit_networking, :connections_local, []) do
      :rpc.call(node, :rabbit_networking, :close_connection, [pid, :force_closed])
    end
  end

  def delete_all_queues() do
    try do
      immediately_delete_all_queues(:rabbit_amqqueue.list())
    catch
      _, _ -> :ok
    end
  end

  def delete_all_queues(vhost) do
    try do
      immediately_delete_all_queues(:rabbit_amqqueue.list(vhost))
    catch
      _, _ -> :ok
    end
  end

  defp immediately_delete_all_queues(qs) do
    for q <- qs do
      try do
        :rpc.call(
          get_rabbit_hostname(),
          :rabbit_amqeueue,
          :delete,
          [q, false, false],
          5000
        )
      catch
        _, _ -> :ok
      end
    end
  end

  def reset_vm_memory_high_watermark() do
    try do
      :rpc.call(
        get_rabbit_hostname(),
        :vm_memory_monitor,
        :set_vm_memory_high_watermark,
        [0.4],
        5000
      )
    catch
      _, _ -> :ok
    end
  end

  def emit_list_multiple_sources(list1, list2, ref, pid) do
    pids = for list <- [list1, list2], do: Kernel.spawn_link(TestHelper, :emit_list, [list, ref, pid])
    :rabbit_control_misc.await_emitters_termination(pids)
  end

  def emit_list(list, ref, pid) do
    emit_list_map(list, &(&1), ref, pid)
  end

  def emit_list_map(list, fun, ref, pid) do
    :rabbit_control_misc.emitting_map(pid, ref, fun, list)
  end

  def run_command_to_list(command, args) do
    res = Kernel.apply(command, :run, args)
    case Enumerable.impl_for(res) do
      nil -> res;
      _   -> Enum.to_list(res)
    end
  end

  def vhost_exists?(vhost) do
    Enum.any?(list_vhosts(), fn(v) -> v[:name] == vhost end)
  end

  def set_enabled_plugins(plugins, mode, node, opts) do
    {:ok, enabled} = PluginHelpers.set_enabled_plugins(plugins, opts)

    PluginHelpers.update_enabled_plugins(enabled, mode, node, opts)
  end

  def currently_active_plugins(context) do
    Enum.sort(:rabbit_misc.rpc_call(context[:opts][:node], :rabbit_plugins, :active, []))
  end

  def enable_federation_plugin() do
    node = get_rabbit_hostname()
    {:ok, plugins_file} = :rabbit_misc.rpc_call(node,
                                                :application, :get_env,
                                                [:rabbit, :enabled_plugins_file])
    {:ok, plugins_dir} = :rabbit_misc.rpc_call(node,
                                               :application, :get_env,
                                               [:rabbit, :plugins_dir])
    rabbitmq_home = :rabbit_misc.rpc_call(node, :code, :lib_dir, [:rabbit])
    {:ok, [_enabled_plugins]} = :file.consult(plugins_file)

    opts = %{enabled_plugins_file: plugins_file,
             plugins_dir: plugins_dir,
             rabbitmq_home: rabbitmq_home,
             online: true, offline: false}

    plugins = currently_active_plugins(%{opts: %{node: node}})
    case Enum.member?(plugins, :rabbitmq_federation) do
      true  -> :ok
      false ->
        set_enabled_plugins(plugins ++ [:rabbitmq_federation], :online, get_rabbit_hostname(), opts)
    end
  end

  def set_vhost_limits(vhost, limits) do
    :rpc.call(get_rabbit_hostname(),
              :rabbit_vhost_limit, :parse_set, [vhost, limits, <<"acting-user">>])
  end
  def get_vhost_limits(vhost) do
    :rpc.call(get_rabbit_hostname(), :rabbit_vhost_limit, :list, [vhost])
    |> Map.new
  end

  def clear_vhost_limits(vhost) do
    :rpc.call(get_rabbit_hostname(), :rabbit_vhost_limit, :clear, [vhost, <<"acting-user">>])
  end

  def set_scope(scope) do
    script_name = Config.get_option(:script_name, %{})
    scopes = Keyword.put(Application.get_env(:rabbitmqctl, :scopes), script_name, scope)
    Application.put_env(:rabbitmqctl, :scopes, scopes)
    CommandModules.load(%{})
  end

  def switch_plugins_directories(old_value, new_value) do
    :rabbit_misc.rpc_call(get_rabbit_hostname(), :application, :set_env,
            [:rabbit, :plugins_dir, new_value])
    ExUnit.Callbacks.on_exit(fn ->
        :rabbit_misc.rpc_call(get_rabbit_hostname(), :application, :set_env,
                [:rabbit, :plugins_dir, old_value])
    end)
  end

  def get_opts_with_non_existing_plugins_directory(context) do
    get_opts_with_plugins_directories(context, ["/tmp/non_existing_rabbitmq_dummy_plugins"])
  end

  def get_opts_with_plugins_directories(context, plugins_directories) do
    opts = context[:opts]
    plugins_dir = opts[:plugins_dir]
    all_directories = Enum.join([to_string(plugins_dir) | plugins_directories], Helpers.path_separator())
    %{opts | plugins_dir: to_charlist(all_directories)}
  end

  def get_opts_with_existing_plugins_directory(context) do
    extra_plugin_directory = System.tmp_dir!() |> Path.join("existing_rabbitmq_dummy_plugins")
    File.mkdir!(extra_plugin_directory)
    ExUnit.Callbacks.on_exit(fn ->
      File.rm_rf(extra_plugin_directory)
    end)
    get_opts_with_plugins_directories(context, [extra_plugin_directory])
  end

  def check_plugins_enabled(plugins, context) do
    {:ok, [xs]} = :file.consult(context[:opts][:enabled_plugins_file])
    assert_equal_sets(plugins, xs)
  end

  def assert_equal_sets(a, b) do
    asorted = Enum.sort(a)
    bsorted = Enum.sort(b)
    assert asorted == bsorted
  end

  def assert_stream_without_errors(stream) do
    true = Enum.all?(stream, fn({:error, _}) -> false;
                               ({:error, _, _}) -> false;
                               (_) -> true end)
  end
end
