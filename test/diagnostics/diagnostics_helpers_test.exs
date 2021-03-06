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

defmodule DiagnosticsHelpersTest do
  use ExUnit.Case, async: true

  alias RabbitMQ.CLI.Diagnostics.Helpers, as: DH
  import RabbitCommon.Records

  test "listener record translation to a map" do
    assert DH.listener_map(listener(node: :rabbit@mercurio,
                           protocol: :stomp,
                           ip_address: {0,0,0,0,0,0,0,0},
                           port: 61613)) ==
      %{
        interface: "[::]",
        node: :rabbit@mercurio,
        port: 61613,
        protocol: :stomp,
        purpose: "STOMP"
      }
  end

  test "[human-readable] protocol labels" do
    assert DH.protocol_label(:amqp)  == "AMQP 0-9-1 and AMQP 1.0"
    assert DH.protocol_label(:mqtt)  == "MQTT"
    assert DH.protocol_label(:stomp) == "STOMP"
  end
end
