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

`ifndef PICORV32_REGS
`ifdef PICORV32_V
`error "picosoc.v must be read before picorv32.v!"
`endif

`define PICORV32_REGS picosoc_regs
`endif

`ifndef PICOSOC_MEM
`define PICOSOC_MEM picosoc_mem
`endif

// this macro can be used to check if the verilog files in your
// design are read in the correct order.
`define PICOSOC_V

module picosoc_AIP (
	input clk,
	input resetn,

	output        iomem_valid,
	input         iomem_ready,
	output [ 3:0] iomem_wstrb,
	output [31:0] iomem_addr,
	output [31:0] iomem_wdata,
	input  [31:0] iomem_rdata,

	input  irq_5,
	input  irq_6,
	input  irq_7,

	output ser_tx,
	input  ser_rx,
	
    //-------------------------- To/From NIc --------------------------//
    input   wire    [4:0]                   conf_dbus,          //Used for protocol to determine different actions types
    input   wire                            read,               //Used for protocol to read different information types
    input   wire                            write,              //Used for protocol to write different information types
    input   wire                            start,              //Used to start the IP-core
    input   wire    [32-1:0]                data_in,            //different data in information types
    output  wire                            int_req,            //Interruption request
    output  wire    [32-1:0]                data_out           //different data out information types
    // -------- 

);
    
	parameter [0:0] BARREL_SHIFTER = 1;
	parameter [0:0] ENABLE_MUL = 1;
	parameter [0:0] ENABLE_DIV = 1;
	parameter [0:0] ENABLE_FAST_MUL = 0;
	parameter [0:0] ENABLE_COMPRESSED = 1;
	parameter [0:0] ENABLE_COUNTERS = 1;
	parameter [0:0] ENABLE_IRQ_QREGS = 0;

	parameter integer MEM_WORDS = 256;
	parameter [31:0] STACKADDR = (4*MEM_WORDS/2);       // end of RAM memory
	parameter [31:0] PROGADDR_RESET = 32'h 0010_0000; // 1 MB into flash
	parameter [31:0] PROGADDR_IRQ = 32'h 0000_0000;

	reg [31:0] irq;
	wire irq_stall = 0;
	wire irq_uart = 0;

	always @* begin
		irq = 0;
		irq[3] = irq_stall;
		irq[4] = irq_uart;
		irq[5] = irq_5;
		irq[6] = irq_6;
		irq[7] = irq_7;
	end

	wire mem_valid;
	wire mem_instr;
	wire mem_ready, mem_readyMEM, mem_readIPCORE;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	wire [31:0] mem_rdata, mem_rdata_mem, mem_rdata_ipcore;

	reg rom_ready;
	wire rom_mem_valid;
	wire [31:0] rom_mem_rdata;

	reg ram_ready;
	wire [31:0] ram_rdata;

 	// IP_Module0
	localparam IP0_BASE_ADDR = 32'h80000100;
	localparam IP0_RANGE     = IP0_BASE_ADDR + 32'h00000100;
       
 	wire         	sel_aip0, mem_readyAIP0;
   	wire [31:0]  	mem_rdata_AIP0;

   	wire [31:0]     iPdataIn0, iPdataOut0;
   	wire            iPwrite0, iPread0, iPstart0;
   	wire [4:0]      iPconf0;
   	wire [15:0]     iPINTstatus0;

   	
   	assign sel_aip0 = (((IP0_BASE_ADDR <= mem_addr) && (mem_addr <= (IP0_RANGE))))? 1'b1 : 1'b0;

	// IP_Module1 (CONV)
	localparam IP1_BASE_ADDR = 32'h80000300; // direccion del convolucionador
	localparam IP1_RANGE     = IP1_BASE_ADDR + 32'h00000100; // top address
       
 	wire         	sel_aip1, mem_readyAIP1;
   	wire [31:0]  	mem_rdata_AIP1;

   	wire [31:0]     iPdataIn1, iPdataOut1;
   	wire            iPwrite1, iPread1, iPstart1;
   	wire [4:0]      iPconf1;
   	wire [15:0]     iPINTstatus1;

   	
   	assign sel_aip1 = (((IP1_BASE_ADDR <= mem_addr) && (mem_addr <= (IP1_RANGE))))? 1'b1 : 1'b0;

	//*************************************************************************************************//

	assign iomem_valid = mem_valid && (mem_addr[31:24] > 8'h 01);
	assign rom_mem_valid = mem_valid && (mem_addr >= 4*MEM_WORDS && mem_addr < 32'h 0200_0000); 
	assign iomem_wstrb = mem_wstrb;
	assign iomem_addr = mem_addr;
	assign iomem_wdata = mem_wdata;

	wire        simpleuart_reg_div_sel = mem_valid && (mem_addr == 32'h 0200_0004);
	wire [31:0] simpleuart_reg_div_do;

	wire        simpleuart_reg_dat_sel = mem_valid && (mem_addr == 32'h 0200_0008);
	wire [31:0] simpleuart_reg_dat_do;
	wire        simpleuart_reg_dat_wait;

	assign mem_ready = (iomem_valid && iomem_ready) || rom_ready || ram_ready ||
			simpleuart_reg_div_sel || (simpleuart_reg_dat_sel && !simpleuart_reg_dat_wait) || (sel_aip0 && mem_readyAIP0) || (sel_aip1 && mem_readyAIP1);

	assign mem_rdata = (iomem_valid && iomem_ready) ? iomem_rdata :rom_ready ? rom_mem_rdata : ram_ready ? ram_rdata : simpleuart_reg_div_sel ? simpleuart_reg_div_do :
			simpleuart_reg_dat_sel ? simpleuart_reg_dat_do : sel_aip0? mem_rdata_AIP0 : sel_aip1? mem_rdata_AIP1 : 32'h 0000_0000;
			

	//*************************************************************************************************//
			

    wire [(4*32)-1:0] rdDataConfigReg;

	picorv32 #(
		.STACKADDR(STACKADDR),
		.PROGADDR_RESET(PROGADDR_RESET),
		.PROGADDR_IRQ(PROGADDR_IRQ),
		.BARREL_SHIFTER(BARREL_SHIFTER),
		.COMPRESSED_ISA(ENABLE_COMPRESSED),
		.ENABLE_COUNTERS(ENABLE_COUNTERS),
		.ENABLE_MUL(ENABLE_MUL),
		.ENABLE_DIV(ENABLE_DIV),
		.ENABLE_FAST_MUL(ENABLE_FAST_MUL),
		.ENABLE_IRQ(1),
		.ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS)
	) cpu (
		.clk         (clk        ),
		.resetn      (resetn  & (!(rdDataConfigReg[0]))   ),
		.mem_valid   (mem_valid  ),
		.mem_instr   (mem_instr  ),
		.mem_ready   (mem_ready  ),
		.mem_addr    (mem_addr   ),
		.mem_wdata   (mem_wdata  ),
		.mem_wstrb   (mem_wstrb  ),
		.mem_rdata   (mem_rdata  ),
		.irq         (irq        )
	);
	
	simpleuart simpleuart (
		.clk         (clk         ),
		.resetn      (resetn      ),

		.ser_tx      (ser_tx      ),
		.ser_rx      (ser_rx      ),

		.reg_div_we  (simpleuart_reg_div_sel ? mem_wstrb : 4'b 0000),
		.reg_div_di  (mem_wdata),
		.reg_div_do  (simpleuart_reg_div_do),

		.reg_dat_we  (simpleuart_reg_dat_sel ? mem_wstrb[0] : 1'b 0),
		.reg_dat_re  (simpleuart_reg_dat_sel && !mem_wstrb),
		.reg_dat_di  (mem_wdata),
		.reg_dat_do  (simpleuart_reg_dat_do),
		.reg_dat_wait(simpleuart_reg_dat_wait)
	);

	always @(posedge clk) begin
		ram_ready <= mem_valid && !mem_ready && mem_addr < 4*MEM_WORDS;
		rom_ready <= mem_valid && !mem_ready && (mem_addr >= 4*MEM_WORDS && mem_addr < 32'h 0200_0000);
	end
	`PICOSOC_MEM #(
		.WORDS(MEM_WORDS/2)
	) memory (
		.clk(clk),
		.wen((mem_valid && !mem_ready && mem_addr < 4*MEM_WORDS) ? mem_wstrb : 4'b0),
		.addr(mem_addr[13:2]),
		.wdata(mem_wdata),
		.rdata(ram_rdata)
	);

    ID0000200F_aip #(
		.WORDS(MEM_WORDS)
	)
    interface_PICORV32
    (
        .clk            (clk        ),
        .rst            (resetn      ),
        .en             (1'b1       ),
  //--- AIP ---//
        .dataInAIP      (data_in    ),
        .dataOutAIP     (data_out   ),
        .configAIP      (conf_dbus  ),
        .readAIP        (read       ),
        .writeAIP       (write      ),
        .startAIP       (start      ),
        .intAIP         (int_req    ),

  //--- IP-core ---//
        .rdDataMemIn_0          (rom_mem_rdata   ),
        .rdAddrMemIn_0          ({5'd0,mem_addr[$clog2(MEM_WORDS)-1 + 2 :2]}),//({8'b0,addrA}    ),
        .wrDataMemOut_0         (          ),
        .wrAddrMemOut_0         (   ),
        .wrEnMemOut_0           (          ),
        .rdDataConfigReg        (rdDataConfigReg),
        .statusIPcore_Busy      (),
        .statusIPcore_readMEM   (),
        .statusIPcore_writeMEM  (),
        .statusIPcore_Trap      (),
        .intIPCore_Done         (),
        .startIPcore            (startIPcore)
);

//************************************************************************************************************//
// interfaces CPU - AIP

	native_aip CPU_to_aip0(
    		.i_clk			(clk),
    		.i_rst			(resetn),

		.i_cpu_mem_valid	(mem_valid),
		.i_cpu_mem_addr		(mem_addr),
		.i_cpu_mem_wdata	(mem_wdata),
		.i_cpu_mem_wen		(mem_valid && !mem_readyAIP0 &&((sel_aip0)? |(mem_wstrb) : 1'b0)),

		.o_cpu_mem_rdata	(mem_rdata_AIP0),
		.o_cpu_mem_ready	(mem_readyAIP0),
		.o_cpu_irq		(),

    // aip interface
    		.i_aip_sel		(sel_aip0),
    		.i_aip_enable		(1'b1),
    		.i_aip_dataOut		(iPdataOut0),
    		.o_aip_dataIn		(iPdataIn0),
    		.o_aip_config		(iPconf0),
    		.o_aip_read		(iPread0),
    		.o_aip_write		(iPwrite0),
    		.o_aip_start		(iPstart0),
    		.i_aip_int		(iPINTstatus0),
    		.o_core_int		()
	);

  
	ID00001001_dummy
	DUMMY0
	(
	    .clk 	(clk),
	    .rst_a 	(resetn),
	    .en_s 	(1'b1),

	    .data_in	(iPdataIn0),
	    .data_out	(iPdataOut0),
	    .write	(iPwrite0),
	    .read	(iPread0),
	    .start	(iPstart0),
	    .conf_dbus	(iPconf0),
	    .int_req	(iPINTstatus0)
	);

	// Instancia Convolucion
	native_aip CPU_to_convolution_core(
    		.i_clk			(clk),
    		.i_rst			(resetn),

		.i_cpu_mem_valid	(mem_valid),
		.i_cpu_mem_addr		(mem_addr),
		.i_cpu_mem_wdata	(mem_wdata),
		.i_cpu_mem_wen		(mem_valid && !mem_readyAIP1 &&((sel_aip1)? |(mem_wstrb) : 1'b0)),

		.o_cpu_mem_rdata	(mem_rdata_AIP1),
		.o_cpu_mem_ready	(mem_readyAIP1),
		.o_cpu_irq		(),

    // aip interface
    		.i_aip_sel			(sel_aip1),
    		.i_aip_enable		(1'b1),
    		.i_aip_dataOut		(iPdataOut1),
    		.o_aip_dataIn		(iPdataIn1),
    		.o_aip_config		(iPconf1),
    		.o_aip_read			(iPread1),
    		.o_aip_write		(iPwrite1),
    		.o_aip_start		(iPstart1),
    		.i_aip_int			(iPINTstatus1),
    		.o_core_int			()
	);

	ID1000500B_conv
	ip_conv_core
	(
		.clk		(clk),
		.rst_a		(resetn),
		.en_s		(1'b1),
		.data_in	(iPdataIn1),      //different data in information types
		.data_out	(iPdataOut1),     //different data out information types
		.write		(iPwrite1),       //Used for protocol to write different information types
		.read		(iPread1),        //Used for protocol to read different information types
		.start		(iPstart1),       //Used to start the IP core
		.conf_dbus	(iPconf1),      //Used for protocol to determine different actions types
		.int_req	(iPINTstatus1)          //Interruption request
	);

//************************************************************************************************************//

endmodule

// Implementation note:
// Replace the following two modules with wrappers for your SRAM cells.

module picosoc_regs (
	input clk, wen,
	input [5:0] waddr,
	input [5:0] raddr1,
	input [5:0] raddr2,
	input [31:0] wdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);
	reg [31:0] regs [0:31];

	always @(posedge clk)
		if (wen) regs[waddr[4:0]] <= wdata;

	assign rdata1 = regs[raddr1[4:0]];
	assign rdata2 = regs[raddr2[4:0]];
endmodule

module picosoc_mem #(
        parameter integer WORDS = 256
) (
        input clk,
        input [3:0] wen,
        input [11:0] addr,
        input [31:0] wdata,
        output reg [31:0] rdata
);
        reg [31:0] mem [0:WORDS-1];
	
	integer i;
	
	initial begin
		for(i=0; i<WORDS; i = i + 1)begin
			mem[i] <= 0;
		end
	end
	
        always @(posedge clk) begin
                rdata <= mem[addr];
                if (wen[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
                if (wen[1]) mem[addr][15: 8] <= wdata[15: 8];
                if (wen[2]) mem[addr][23:16] <= wdata[23:16];
                if (wen[3]) mem[addr][31:24] <= wdata[31:24];
        end

endmodule

module picosoc_mem_rom #(
	parameter integer WORDS = 256
) (
	input clk,
	//input [3:0] wen,
	input [$clog2(WORDS)-1:0] addr,
	//input [31:0] wdata,
	output reg [31:0] rdata
);

	reg [31:0] mem [0:WORDS-1];

	initial begin
		$readmemh("altera_out.txt", mem);
	end
// initial
// begin
//     $readmemb("init.txt", rom);
// end	
	always @(posedge clk) begin
		rdata <= mem[addr];
		/*if (wen[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
		if (wen[1]) mem[addr][15: 8] <= wdata[15: 8];
		if (wen[2]) mem[addr][23:16] <= wdata[23:16];
		if (wen[3]) mem[addr][31:24] <= wdata[31:24];*/
	end

endmodule

