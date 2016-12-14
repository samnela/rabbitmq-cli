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
## Copyright (c) 2007-2016 Pivotal Software, Inc.  All rights reserved.


defmodule RabbitMQ.CLI.Diagnostics.Commands.ErlangCookieHashCommand do
  @behaviour RabbitMQ.CLI.CommandBehaviour

  def merge_defaults(args, opts), do: {args, opts}

  def validate(args, _) when length(args) > 0 do
    {:validation_failure, :too_many_args}
  end
  def validate(_, _), do: :ok

  def usage, do: "erlang_cookie_hash"

  def run([], %{node: node_name, timeout: timeout}) do
    :rabbit_misc.rpc_call(node_name, :rabbit_nodes, :cookie_hash, [], timeout)
  end

  def output(result, options) when is_list(result) do
    {:ok, result}
  end
  use RabbitMQ.CLI.DefaultOutput

  def banner([], %{node: node_name}) do
    "Asking node #{node_name} its Erlang cookie hash..."
  end

  def formatter(), do: RabbitMQ.CLI.Formatters.ErlangString
end