/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Claire Xenia Wolf <claire@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`ifdef PICOSOC_V
`error "max10_picosoc.v must be read before picosoc.v!"
`endif


module picosoc_AIP_DDS (
	input clk,
   input rst,
	input ena,
	output ser_tx,
	input ser_rx,

	output led1,
	output led2,
	output led3,
	output led4,
	output led5,

	output ledr_n,
	output ledg_n,
	
	output [11:0]oData_Tx_I,
	output [11:0]oData_Tx_Q,
	output clk_12Mhz
	/*,
	
	output rom_mem_valid,
	output mem_valid,
	output rom_ready,
	output ram_ready,
	output iomem_valid,
	
	output [15:0] rom_debug*/

/*	output flash_csb,
	output flash_clk,
	inout  flash_io0,
	inout  flash_io1,
	inout  flash_io2,
	inout  flash_io3*/
);

//wire clk_12Mhz;
reg [1:0] cont;
wire locked;

/*pll_CLK_12Mhz (
	.areset(rst),
	.inclk0(clk),
	.c0(clk_12Mhz),
	.locked(locked)
	);*/
	always@(posedge clk)begin
	if(!rst)
	   cont = 0;
	else
		cont <= cont + 1'b1;
	end
	assign clk_12Mhz = (cont== 2'b11)? 1'b1: 1'b0;
	//parameter integer MEM_WORDS = 32768;
	parameter integer MEM_WORDS = 2048;

	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt;

	always @(posedge clk_12Mhz or negedge rst) begin
	if(!rst)
		reset_cnt = 0;
	else
	   if(ena)
			reset_cnt <= reset_cnt + !resetn;
	end

	wire [7:0] leds;

	assign led1 = leds[1];
	assign led2 = leds[2];
	assign led3 = leds[3];
	assign led4 = leds[4];
	assign led5 = leds[5];

	assign ledr_n = leds[6];
	assign ledg_n = leds[7];

	wire        iomem_valid;
	reg         iomem_ready;
	wire [3:0]  iomem_wstrb;
	wire [31:0] iomem_addr;
	wire [31:0] iomem_wdata;
	reg  [31:0] iomem_rdata;

	reg [31:0] gpio;
	assign leds = gpio;

	always @(posedge clk_12Mhz) begin
		if (!resetn) begin
			gpio <= 0;
		end else begin
			iomem_ready <= 0;
			if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h 03) begin
				iomem_ready <= 1;
				iomem_rdata <= gpio;
				if (iomem_wstrb[0]) gpio[ 7: 0] <= iomem_wdata[ 7: 0];
				if (iomem_wstrb[1]) gpio[15: 8] <= iomem_wdata[15: 8];
				if (iomem_wstrb[2]) gpio[23:16] <= iomem_wdata[23:16];
				if (iomem_wstrb[3]) gpio[31:24] <= iomem_wdata[31:24];
			end
		end
	end

	picosoc_dds #(
		.BARREL_SHIFTER(0),
		.ENABLE_MUL(0),
		.ENABLE_DIV(0),
		.ENABLE_FAST_MUL(1),
		.MEM_WORDS(MEM_WORDS)
	) soc (
		.clk          (clk_12Mhz         ),
		.resetn       (resetn      ),

		.ser_tx       (ser_tx      ),
		.ser_rx       (ser_rx      ),

		.irq_5        (1'b0        ),
		.irq_6        (1'b0        ),
		.irq_7        (1'b0        ),

		.iomem_valid  (iomem_valid ),
		.iomem_ready  (iomem_ready ),
		.iomem_wstrb  (iomem_wstrb ),
		.iomem_addr   (iomem_addr  ),
		.iomem_wdata  (iomem_wdata ),
		.iomem_rdata  (iomem_rdata ),
		
		.iData_Tx_I   (oData_Tx_I),
		.iData_Tx_Q   (oData_Tx_Q)

	);
endmodule
