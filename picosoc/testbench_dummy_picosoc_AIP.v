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

`timescale 1 ns / 1 ps

module testbench_dummy_picosoc_AIP;
            //----------------------------------------------------------
            //.......MANDATORY TB PARAMETERS............................
            //----------------------------------------------------------
localparam  CYCLE		  = 'd20, // Define the clock work cycle in ns (user)
            DATAWIDTH     = 'd32, // AIP BITWIDTH
            MAX_SIZE_MEM  = 'd256,  // MAX MEMORY SIZE AMONG ALL AIP MEMORIES (Defined by the user)
            //------------------------------------------------------------
            //..................CONFIG VALUES.............................
            //------------------------------------------------------------           
            STATUS        = 5'd30,//Mandatory config
            IP_ID         = 5'd31,//Mandatory config
            MProgramMEMIN = 5'd0, // Config values defined in the CSV file
            AProgramMEMIN = 5'd1,
            MMEMOUT       = 5'd2, // Config values defined in the CSV file
            AMEMOUT       = 5'd3,
            CCONFREG      = 5'd4,
            ACONFREG      = 5'd5,
            //------------------------------------------------------------
            //..................PARAMETERS DEFINED BY THE USER............
            //------------------------------------------------------------
            SIZE_MEM0    = 'd2048, //Size of the memories of the IP PICORV32
            INT_BIT_DONE = 'd0; //Bit corresponding to the Int Done flag.

    reg clk, rst_a, en_s;
    reg 			 iStartIPcore;

    //Clock source procedural block
    always #(CYCLE/2) clk = !clk;
	//always #5 clk = (clk === 1'b0);

	localparam ser_half_period = 53;
	event ser_sample;

	initial begin
		$dumpfile("testbench.vcd");
		$dumpvars(0, testbench_dummy_picosoc_AIP);
		repeat (6) begin
			repeat (50000) @(posedge clk);
			$display("+50000 cycles");
		end
		$finish;
	end
    
    integer i;
    reg [DATAWIDTH-1:0] 	        tb_data;
    reg [DATAWIDTH-1:0] 		    dataSet [SIZE_MEM0-1:0];
    reg [(DATAWIDTH*SIZE_MEM0)-1:0] dataSet_packed;

	integer cycle_cnt = 0;

	always @(posedge clk) begin
		cycle_cnt <= cycle_cnt + 1;
	end
        
    wire rst;
    assign rst = ((cycle_cnt > 50) || (cycle_cnt <  5) )? 1'b1 : 1'b0;
        
	wire led1, led2, led3, led4, led5;
	wire ledr_n, ledg_n;

	wire [6:0] leds = {!ledg_n, !ledr_n, led5, led4, led3, led2, led1};
     //AIP Interface signals
    reg			        readAIP;
    reg			        writeAIP;
    reg			        startAIP;
    reg	[ 4:0] 	        configAIP;
    reg	[DATAWIDTH-1:0] dataInAIP;

    wire		    	     intAIP;
    wire	[DATAWIDTH-1:0]  dataOutAIP;

	wire ser_rx;
	wire ser_tx;


  always @(leds) begin
		#1 $display("%b", leds);
	end

	ipdummy_picosoc 
		// We limit the amount of memory in simulation
		// in order to avoid reduce simulation time
		// required for intialization of RAM
		//.MEM_WORDS(256)
	 uut (
		.clk           (clk      ),
		.rst           (rst_a    ), 
		.ena	       (en_s     ),
		.led1          (led1     ),
		.led2          (led2     ),
		.led3          (led3     ),
		.led4          (led4     ),
		.led5          (led5     ),
		.ledr_n        (ledr_n   ),
		.ledg_n        (ledg_n   ),
		.ser_rx        (ser_rx   ),
		.ser_tx        (ser_tx   ),
			  //--- AIP ---//
        .data_in       (dataInAIP  ),
        .data_out      (dataOutAIP ),
        .conf_dbus     (configAIP  ),
        .read          (readAIP    ),
        .write         (writeAIP   ),
        .start         (startAIP   ),
        .int_req       (intAIP     )
	);

wire clk_12Mhz;
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
	assign clk_12Mhz = clk;//(cont== 2'b11)? 1'b1: 1'b0;

	reg [7:0] buffer;

	always begin
		@(negedge ser_tx);

		repeat (ser_half_period) @(posedge clk_12Mhz);
		-> ser_sample; // start bit

		repeat (8) begin
			repeat (ser_half_period) @(posedge clk_12Mhz);
			repeat (ser_half_period) @(posedge clk_12Mhz);
			buffer = {ser_tx, buffer[7:1]};
			-> ser_sample; // data bit
		end

		repeat (ser_half_period) @(posedge clk_12Mhz);
		repeat (ser_half_period) @(posedge clk_12Mhz);
		-> ser_sample; // stop bit

		if (buffer < 32 || buffer >= 127)
			$display("Serial data: %d", buffer);
		else
			$display("Serial data: '%c'", buffer);
	end

	reg [31:0] mem [0:2048-1];

	initial begin
		$readmemh("../picosoc/firmware/altera_out.txt", mem);
		//$readmemh("altera_out.txt", mem);
	end

initial 
begin
	clk		        = 1'b1;
	en_s		    = 1'b1;
	readAIP	        = 1'b0;
	writeAIP	    = 1'b0;
	startAIP	    = 1'b0;
	configAIP   	= 5'd0;
	dataInAIP   	= 32'd0;
    i               = 'd0;
    iStartIPcore 	= 1'b1;
	rst_a		= 1'b0;	// reset is active
	#(CYCLE) rst_a	= 1'b1;	// at time #n release reset
	#(500*CYCLE)
     // READ IP_ID
    getID(tb_data);
    $display ("%7T Read ID %h", $time, tb_data);
     
    // READ STATUS
    getStatus(tb_data);
    $display ("%7T Read STATUS %h", $time, tb_data);
     
    //(INTERRUPTIONS) 
    //FOR ENABLING INTERRUPTIONS
    enableINT(INT_BIT_DONE);
     
    writeConfReg(CCONFREG, 1, 1,0);  // Reset CPU -- .resetn(resetn  & (!(rdDataConfigReg[0]))   ),
    //****CONVERTION TO A SINGLE ARRAY
    for (i = 0; i < (SIZE_MEM0) ; i=i+1) begin 
        dataSet_packed[DATAWIDTH*i+:DATAWIDTH] = mem[i]; 
        $display("%7T PROGRAM  addr%h: word %h", $time,i,mem[i]);
    end        
    
    $display("%7T writing PROGRAM to MEMIN0", $time);
    writeMem(MProgramMEMIN, dataSet_packed, SIZE_MEM0,0);

    
	#(50*CYCLE)
    writeConfReg(CCONFREG, 0, 1,0);  // Reset CPU -- .resetn(resetn  & (!(rdDataConfigReg[0]))   ),
     // START PROCESS
    $display("%7T Sending start", $time);
    start();
    // START PROCESS
    $display("%7T Sending start", $time);
    #(1000*CYCLE);
	$display($time, " << finishing Simulation >>");
end


//*******************************************************************
//*********************TASKS DEFINITION******************************
//*******************************************************************

task getID;
   output [DATAWIDTH-1:0] read_ID;
      
      begin
         single_read(IP_ID,read_ID);
      end
endtask

task getStatus;
   output [DATAWIDTH-1:0] read_status;
      
      begin
         single_read(STATUS,read_status);
      end
endtask

task writeMem;
        input [                         4:0] config_value;
        input [(DATAWIDTH*MAX_SIZE_MEM)-1:0] write_data;
        input [               DATAWIDTH-1:0] length;
        input [               DATAWIDTH-1:0] offset;
        
        begin        
            //SET POINTER
            single_write(config_value+1, offset);
            
            //WRITE MEMORY
            configAIP = config_value;
            #(CYCLE)
            for(i=0; i < length ; i= i+1) begin
               dataInAIP = mem[i];//write_data[(i*DATAWIDTH)+:DATAWIDTH];
               #(CYCLE);
               writeAIP = 1'b1;
               #(CYCLE);
               writeAIP = 1'b0;
            end
            writeAIP = 1'b0;
            #(CYCLE);
        end
endtask

task writeConfReg;
        input [                         4:0] config_value;
        input [(DATAWIDTH*MAX_SIZE_MEM)-1:0] write_data;
        input [               DATAWIDTH-1:0] length;
        input [               DATAWIDTH-1:0] offset;
        
        begin        
            //SET POINTER
            single_write(config_value+1, offset);
            
            //WRITE MEMORY
            configAIP = config_value;
            #(CYCLE)
            for(i=0; i < length ; i= i+1) begin
               dataInAIP = write_data[(i*DATAWIDTH)+:DATAWIDTH];
               #(CYCLE);
               writeAIP = 1'b1;
               #(CYCLE);
            end
            writeAIP = 1'b0;
            #(CYCLE);
        end
endtask



task readMem;
        input [                         4:0] config_value;   
        output[(DATAWIDTH*MAX_SIZE_MEM)-1:0] read_data;     
        input [               DATAWIDTH-1:0] length;
        input [               DATAWIDTH-1:0] offset;        
        
        begin
            //SET POINTER
            single_write(config_value+1, offset);
        
            configAIP = config_value;
            #(CYCLE)
            for(i=0; i < length ; i= i+1) begin               
               readAIP = 1'b1;
               #(CYCLE);
               read_data[(i*DATAWIDTH)+:DATAWIDTH]=dataOutAIP;
            end
            readAIP = 1'b0;
            #(CYCLE);
        end
endtask

task enableINT;
      input [3:0] idxInt;   
      
       reg [DATAWIDTH-1:0] read_status;
       reg [7:0] mask;
       
  begin

       getStatus(read_status);
       
       mask = read_status[23:16]; //previous stored mask
       mask[idxInt] = 1'b1; //enabling INT bit

       single_write(STATUS, {8'd0,mask,16'd0});//write status reg
  end
endtask

task disableINT;
      input [3:0] idxInt;   
      
       reg [DATAWIDTH-1:0] read_status;
       reg [7:0] mask;
  begin
   
       getStatus(read_status);
       
       mask = read_status[23:16]; //previous stored mask
       mask[idxInt] = 1'b0; //disabling INT bit

       single_write(STATUS, {8'd0,mask,16'd0});//write status reg
  end
endtask

task clearINT;
      input [3:0] idxInt;   
      
       reg [DATAWIDTH-1:0] read_status;
       reg [7:0] clear_value;
       reg [7:0] mask;
    
  begin
    
       getStatus(read_status);
       
       mask = read_status[23:16]; //previous stored mask
       clear_value = 7'd1 <<  idxInt;

       single_write(STATUS, {8'd0,mask,8'd0,clear_value});//write status reg
  end
endtask

task start;
  begin
      startAIP = 1'b1;
      #(CYCLE);
      startAIP = 1'b0;
      #(CYCLE);
  end
endtask

task single_write;
        input [          4:0] config_value;
        input [DATAWIDTH-1:0] write_data;
        begin
            configAIP = config_value;
            dataInAIP = write_data;
            #(CYCLE)
            writeAIP = 1'b1;
            #(CYCLE)
            writeAIP = 1'b0;
            #(CYCLE);
        end
endtask

task single_read;
  input  [          4:0] config_value;
  output [DATAWIDTH-1:0] read_data;
  begin
      configAIP = config_value;
      #(CYCLE);
      readAIP = 1'b1;
      #(CYCLE);
      read_data = dataOutAIP;
      readAIP = 1'b0;
      #(CYCLE);
  end
endtask	

endmodule
