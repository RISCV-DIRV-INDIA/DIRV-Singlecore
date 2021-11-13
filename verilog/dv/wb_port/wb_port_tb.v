// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 1 ps

`include "uprj_netlists.v"
`include "caravel_netlists.v"
`include "spiflash.v"

module wb_port_tb;
	reg clock;
	reg RSTB;
	reg CSB;
	reg power1, power2;
	reg power3, power4;

	wire gpio;
	wire [37:0] mprj_io;
	wire [7:0] mprj_io_0;
	wire [15:0] checkbits;

	assign checkbits = mprj_io[31:16];

	assign mprj_io[3] = (CSB == 1'b1) ? 1'b1 : 1'bz;

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #12.5 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	`ifdef WFDUMP
	initial begin
		$dumpfile("wb_port.vcd");
		$dumpvars(1, wb_port_tb);
		$dumpvars(2, wb_port_tb.uut);
		//$dumpvars(1, wb_port_tb.uut.mprj);
		$dumpvars(1, wb_port_tb.uut.mprj.u_wb_host);
		$dumpvars(2, wb_port_tb.uut.mprj.u_pinmux);
	end
       `endif

	initial begin

		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (30) begin
			repeat (1000) @(posedge clock);
			// $display("+1000 cycles");
		end
		$display("%c[1;31m",27);
		$display ("##########################################################");
		`ifdef GL
			$display ("Monitor: Timeout, Test Mega-Project WB Port (GL) Failed");
		`else
			$display ("Monitor: Timeout, Test Mega-Project WB Port (RTL) Failed");
		`endif
		$display ("##########################################################");
		$display("%c[0m",27);
		$finish;
	end

	initial begin
	   wait(checkbits == 16'h AB60);
		$display("Monitor: MPRJ-Logic WB Started");
		wait(checkbits == 16'h AB6A);
		$display ("##########################################################");
		`ifdef GL
	    	$display("Monitor: Mega-Project WB (GL) Passed");
		`else
		    $display("Monitor: Mega-Project WB (RTL) Passed");
		`endif
		$display ("##########################################################");
	    $finish;
	end

	initial begin
		RSTB <= 1'b0;
		CSB  <= 1'b1;		// Force CSB high
		#2000;
		RSTB <= 1'b1;	    	// Release reset
		#170000;
		CSB = 1'b0;		// CSB can be released
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		power3 <= 1'b0;
		power4 <= 1'b0;
		#100;
		power1 <= 1'b1;
		#100;
		power2 <= 1'b1;
		#100;
		power3 <= 1'b1;
		#100;
		power4 <= 1'b1;
	end

	//always @(mprj_io) begin
	//	#1 $display("MPRJ-IO state = %b ", mprj_io[7:0]);
	//end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD3V3 = power1;
	wire VDD1V8 = power2;
	wire USER_VDD3V3 = power3;
	wire USER_VDD1V8 = power4;
	wire VSS = 1'b0;

	caravel uut (
		.vddio	  (VDD3V3),
		.vssio	  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (USER_VDD3V3),
		.vdda2    (USER_VDD3V3),
		.vssa1	  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (USER_VDD1V8),
		.vccd2	  (USER_VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock	  (clock),
		.gpio     (gpio),
        .mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("wb_port.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

`ifndef GL // Drive Power for Hold Fix Buf
    // All standard cell need power hook-up for functionality work
    initial begin
	force uut.mprj.u_qspi_master.u_delay1_sdio0.VPWR =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay1_sdio0.VPB  =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay1_sdio0.VGND =VSS;
	force uut.mprj.u_qspi_master.u_delay1_sdio0.VNB  = VSS;
	force uut.mprj.u_qspi_master.u_delay2_sdio0.VPWR =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay2_sdio0.VPB  =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay2_sdio0.VGND =VSS;
	force uut.mprj.u_qspi_master.u_delay2_sdio0.VNB  = VSS;
	force uut.mprj.u_qspi_master.u_buf_sdio0.VPWR    =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_buf_sdio0.VPB     =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_buf_sdio0.VGND    =VSS;
	force uut.mprj.u_qspi_master.u_buf_sdio0.VNB     =VSS;


	force uut.mprj.u_qspi_master.u_delay1_sdio1.VPWR =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay1_sdio1.VPB  =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay1_sdio1.VGND =VSS;
	force uut.mprj.u_qspi_master.u_delay1_sdio1.VNB = VSS;
	force uut.mprj.u_qspi_master.u_delay2_sdio1.VPWR =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay2_sdio1.VPB  =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay2_sdio1.VGND =VSS;
	force uut.mprj.u_qspi_master.u_delay2_sdio1.VNB = VSS;
	force uut.mprj.u_qspi_master.u_buf_sdio1.VPWR    =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_buf_sdio1.VPB     =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_buf_sdio1.VGND    =VSS;
	force uut.mprj.u_qspi_master.u_buf_sdio1.VNB     =VSS;

	force uut.mprj.u_qspi_master.u_delay1_sdio2.VPWR =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay1_sdio2.VPB  =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay1_sdio2.VGND =VSS;
	force uut.mprj.u_qspi_master.u_delay1_sdio2.VNB = VSS;
	force uut.mprj.u_qspi_master.u_delay2_sdio2.VPWR =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay2_sdio2.VPB  =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay2_sdio2.VGND =VSS;
	force uut.mprj.u_qspi_master.u_delay2_sdio2.VNB = VSS;
	force uut.mprj.u_qspi_master.u_buf_sdio2.VPWR    =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_buf_sdio2.VPB     =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_buf_sdio2.VGND    =VSS;
	force uut.mprj.u_qspi_master.u_buf_sdio2.VNB     =VSS;

	force uut.mprj.u_qspi_master.u_delay1_sdio3.VPWR =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay1_sdio3.VPB  =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay1_sdio3.VGND =VSS;
	force uut.mprj.u_qspi_master.u_delay1_sdio3.VNB = VSS;
	force uut.mprj.u_qspi_master.u_delay2_sdio3.VPWR =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay2_sdio3.VPB  =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_delay2_sdio3.VGND =VSS;
	force uut.mprj.u_qspi_master.u_delay2_sdio3.VNB = VSS;
	force uut.mprj.u_qspi_master.u_buf_sdio3.VPWR    =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_buf_sdio3.VPB     =USER_VDD1V8;
	force uut.mprj.u_qspi_master.u_buf_sdio3.VGND    =VSS;
	force uut.mprj.u_qspi_master.u_buf_sdio3.VNB     =VSS;
          
	force uut.mprj.u_uart_i2c_usb_spi.u_uart_core.u_lineclk_buf.VPWR =USER_VDD1V8;
	force uut.mprj.u_uart_i2c_usb_spi.u_uart_core.u_lineclk_buf.VPB  =USER_VDD1V8;
	force uut.mprj.u_uart_i2c_usb_spi.u_uart_core.u_lineclk_buf.VGND =VSS;
	force uut.mprj.u_uart_i2c_usb_spi.u_uart_core.u_lineclk_buf.VNB = VSS;

	force uut.mprj.u_wb_host.u_buf_wb_rst.VPWR =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_buf_wb_rst.VPB  =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_buf_wb_rst.VGND =VSS;
	force uut.mprj.u_wb_host.u_buf_wb_rst.VNB = VSS;

	force uut.mprj.u_wb_host.u_buf_cpu_rst.VPWR =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_buf_cpu_rst.VPB  =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_buf_cpu_rst.VGND =VSS;
	force uut.mprj.u_wb_host.u_buf_cpu_rst.VNB = VSS;

	force uut.mprj.u_wb_host.u_buf_qspim_rst.VPWR =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_buf_qspim_rst.VPB  =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_buf_qspim_rst.VGND =VSS;
	force uut.mprj.u_wb_host.u_buf_qspim_rst.VNB = VSS;

	force uut.mprj.u_wb_host.u_buf_sspim_rst.VPWR =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_buf_sspim_rst.VPB  =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_buf_sspim_rst.VGND =VSS;
	force uut.mprj.u_wb_host.u_buf_sspim_rst.VNB = VSS;

	force uut.mprj.u_wb_host.u_buf_uart_rst.VPWR =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_buf_uart_rst.VPB  =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_buf_uart_rst.VGND =VSS;
	force uut.mprj.u_wb_host.u_buf_uart_rst.VNB = VSS;

	force uut.mprj.u_wb_host.u_buf_i2cm_rst.VPWR =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_buf_i2cm_rst.VPB  =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_buf_i2cm_rst.VGND =VSS;
	force uut.mprj.u_wb_host.u_buf_i2cm_rst.VNB = VSS;

	force uut.mprj.u_wb_host.u_buf_usb_rst.VPWR =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_buf_usb_rst.VPB  =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_buf_usb_rst.VGND =VSS;
	force uut.mprj.u_wb_host.u_buf_usb_rst.VNB = VSS;

	force uut.mprj.u_wb_host.u_clkbuf_cpu.VPWR =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_clkbuf_cpu.VPB  =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_clkbuf_cpu.VGND =VSS;
	force uut.mprj.u_wb_host.u_clkbuf_cpu.VNB = VSS;

	force uut.mprj.u_wb_host.u_clkbuf_rtc.VPWR =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_clkbuf_rtc.VPB  =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_clkbuf_rtc.VGND =VSS;
	force uut.mprj.u_wb_host.u_clkbuf_rtc.VNB = VSS;

	force uut.mprj.u_wb_host.u_clkbuf_usb.VPWR =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_clkbuf_usb.VPB  =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_clkbuf_usb.VGND =VSS;
	force uut.mprj.u_wb_host.u_clkbuf_usb.VNB = VSS;

	force uut.mprj.u_wb_host.u_cpu_ref_sel.u_mux.VPWR =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_cpu_ref_sel.u_mux.VPB  =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_cpu_ref_sel.u_mux.VGND =VSS;
	force uut.mprj.u_wb_host.u_cpu_ref_sel.u_mux.VNB = VSS;

	force uut.mprj.u_wb_host.u_cpu_clk_sel.u_mux.VPWR =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_cpu_clk_sel.u_mux.VPB  =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_cpu_clk_sel.u_mux.VGND =VSS;
	force uut.mprj.u_wb_host.u_cpu_clk_sel.u_mux.VNB = VSS;

	force uut.mprj.u_wb_host.u_wbs_clk_sel.u_mux.VPWR =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_wbs_clk_sel.u_mux.VPB  =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_wbs_clk_sel.u_mux.VGND =VSS;
	force uut.mprj.u_wb_host.u_wbs_clk_sel.u_mux.VNB = VSS;

	force uut.mprj.u_wb_host.u_usb_clk_sel.u_mux.VPWR =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_usb_clk_sel.u_mux.VPB  =USER_VDD1V8;
	force uut.mprj.u_wb_host.u_usb_clk_sel.u_mux.VGND =VSS;
	force uut.mprj.u_wb_host.u_usb_clk_sel.u_mux.VNB = VSS;
    end
`endif    
endmodule
`default_nettype wire
