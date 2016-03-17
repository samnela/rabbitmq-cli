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


defmodule RabbitMQCtl do
  import Parser
  import Helpers

  def main(command) do
    :net_kernel.start([:rabbitmqctl, :shortnames])

    {parsed_cmd, options} = parse(command)

    case Helpers.is_command? parsed_cmd do
      false -> HelpCommand.help
      true  -> options |> autofill_defaults |> run_command(parsed_cmd)
    end

    :net_kernel.stop()
  end

  def autofill_defaults(%{} = options) do
    options
    |> autofill_node
    |> autofill_timeout
  end

  defp autofill_node(%{} = opts), do: opts |> Map.put_new(:node, get_rabbit_hostname)

  defp autofill_timeout(%{} = opts), do: opts |> Map.put_new(:timeout, :infinity)

  defp run_command(_, []), do: HelpCommand.help
  defp run_command(options, [cmd | arguments]) do
    connect_to_rabbitmq(options[:node])
    {result, _} = Code.eval_string(
      "#{command_string(cmd)}(args, opts)",
      [args: arguments, opts: options]
    )

    case result do
      {:badrpc, :nodedown}  -> print_nodedown_error(options)
      {:badrpc, :timeout}   -> print_timeout_error(options)
      _                     -> IO.inspect result
    end
  end

  defp command_string(cmd_name) do
    "#{Helpers.commands[cmd_name]}.#{cmd_name}"
  end

  defp print_nodedown_error(options) do
    IO.puts "Status of #{options[:node]} ..."
    IO.puts "Error: unable to connect to node '#{options[:node]}': nodedown"
  end

  defp print_timeout_error(options) do
    IO.puts "Error: {timeout, #{options[:timeout]}}"
  end
end