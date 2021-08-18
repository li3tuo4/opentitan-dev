// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// xbar_cover.cfg generated by `tlgen.py` tool
<%
  import math
  # or all start & end addresses to get toggle_bits
  def get_device_addr_toggle_bits(dev_name):
    for device in xbar.devices:
      if device.name == dev_name:
        for i in range(len(device.addr_range)):
          if i == 0:
            toggle_bits = device.addr_range[i][0]
          else:
            toggle_bits ^= device.addr_range[i][0]
        for addr in device.addr_range:
          toggle_bits |= addr[1] - addr[0]

        return toggle_bits
    log.error("Invalid dev_name: {}".format(dev_name))

  num_hosts = len(xbar.hosts)
  if num_hosts > 1:
    host_unr_source_bits = math.ceil(math.log2(num_hosts))
  else:
    host_unr_source_bits = 0
%>\

+tree tb.dut
-module pins_if     // DV construct.
-module clk_rst_if  // DV construct.

// due to VCS issue (fixed at VCS/2020.12), can't move this part into begin...end (tgl) or after.
-node tb.dut tl_*.a_param
-node tb.dut tl_*.d_param
-node tb.dut tl_*.d_opcode[2:1]

// [UNR] these device address bits are always 0
  % for device in xbar.devices:
<%
    # assume toggle_bits = 0011, generate below as bit 2 and 3 are never toggled
    # -node address[3:2]
    toggle_bits = get_device_addr_toggle_bits(device.name)
    start_bit = 0
    saw_first_zero = 0

    esc_name = device.name.replace('.', '__')
%>\
    % for i in range(32):
      % if toggle_bits % 2 == 0:
        % if saw_first_zero == 0:
<%
        start_bit = i
        saw_first_zero = 1
%>\
        % endif
      % elif saw_first_zero == 1:
-node tb.dut tl_${esc_name}_o.a_address[${i-1}:${start_bit}]
<%
        saw_first_zero = 0
%>\
      % endif
<%
      toggle_bits = toggle_bits >> 1
%>\
    % endfor
    % if saw_first_zero == 1:
-node tb.dut tl_${esc_name}_o.a_address[31:${start_bit}]
    % endif
  % endfor

% if host_unr_source_bits > 0:
-node tb.dut tl_*.a_source[7:${7 - host_unr_source_bits}]
-node tb.dut tl_*.d_source[7:${7 - host_unr_source_bits}]
% endif
begin tgl
  -tree tb
  +tree tb.dut 1
  -node tb.dut.scanmode_i
end

