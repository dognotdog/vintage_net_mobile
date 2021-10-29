defmodule VintageNetMobile.Modem.HuaweiE3372h.Modeswitch do
  @moduledoc """
  VintageNetMobile PowerManager to handle the Huawei E3372h-510 (or -153) modem, which shows up as an ethernet interface in HiLink mode, as opposed to the CDC-NCM mode of the E3372 without an `h`. The `VintageNetEthernet` driver works in HiLink mode.

  A lot of these modems seem to develop problems over their lifetime. Usually on Linux, eg. Raspbian, drivers are in place to bring the modem into HiLink mode, and its functionality can be checked through the web interface it provides. If it's unable to connect to the mobile network, it will present as a captive portal, routing all traffic to itself.
  """

  require Logger
  @behaviour VintageNet.PowerManager

  @impl VintageNet.PowerManager
  def init(_args) do
    {:ok, {}}
  end

  @impl VintageNet.PowerManager
  def power_on(state) do
    # Modem starts out as storage device, trigger modeswitch into HiLink mode
    _ = safe_cmd("usb_modeswitch", ["-v 12d1", "-p 1f01", "-J"]) # -> 14dc
    {:ok, state, 600}
  end

  @impl VintageNet.PowerManager
  def start_powering_off(state) do
    # If there's a graceful power off, start it here and return
    # the max time it takes.
    {:ok, state, 0}
  end

  @impl VintageNet.PowerManager
  def power_off(state) do
    # Attempt modeswitch out of HiLink mode
    _ = safe_cmd("usb_modeswitch", ["-v 12d1", "-p 14dc", "-J"])

    {:ok, state, 30}
  end

  @impl VintageNet.PowerManager
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp safe_cmd(cmd, args) do
    do_safe_cmd(System.find_executable(cmd), args)
  end

  defp do_safe_cmd(nil, _args) do
    Logger.error("usb_modeswitch not found in path")
    {:error, :enoent}
  end

  defp do_safe_cmd(path, args) do
    case System.cmd(path, args) do
      {_output, 0} ->
        :ok

      {output, _status} ->
        Logger.error("Huawei E3372h modeswitch failed with '#{output}'")
        {:error, :error_exit}
    end
  end
end
