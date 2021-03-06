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
## The Initial Developer of the Original Code is Pivotal Software, Inc.
## Copyright (c) 2016-2017 Pivotal Software, Inc.  All rights reserved.

require Integer

defmodule RabbitMQ.CLI.Ctl.Commands.RenameClusterNodeCommand do
  alias RabbitMQ.CLI.Core.Validators
  import Rabbitmq.Atom.Coerce

  @behaviour RabbitMQ.CLI.CommandBehaviour
  use RabbitMQ.CLI.DefaultOutput

  def merge_defaults(args, opts), do: {args, opts}

  def validate([], _), do: {:validation_failure, :not_enough_args}
  def validate([_], _), do: {:validation_failure, :not_enough_args}

  def validate(_, _) do
    :ok
  end

  def validate_execution_environment(args, opts) do
    Validators.chain(
      [
        &validate_args_count_even/2,
        &Validators.node_is_not_running/2,
        &Validators.mnesia_dir_is_set/2,
        &Validators.rabbit_is_loaded/2
      ],
      [args, opts]
    )
  end

  def run(nodes, %{node: node_name}) do
    node_pairs = make_node_pairs(nodes)

    try do
      :rabbit_mnesia_rename.rename(node_name, node_pairs)
    catch
      _, reason ->
        {:rename_failed, reason}
    end
  end

  defp validate_args_count_even(args, _) do
    case agrs_count_even?(args) do
      true ->
        :ok

      false ->
        {:validation_failure,
         {:bad_argument, "Argument list should contain even number of nodes"}}
    end
  end

  defp agrs_count_even?(args) do
    Integer.is_even(length(args))
  end

  defp make_node_pairs([]) do
    []
  end

  defp make_node_pairs([from, to | rest]) do
    [{to_atom(from), to_atom(to)} | make_node_pairs(rest)]
  end

  def usage() do
    "rename_cluster_node <oldnode1> <newnode1> [oldnode2] [newnode2] ..."
  end

  def banner(args, _) do
    [
      "Renaming cluster nodes: \n ",
      for {node_from, node_to} <- make_node_pairs(args) do
        "#{node_from} -> #{node_to} \n"
      end
    ]
    |> List.flatten()
    |> Enum.join()
  end
end
