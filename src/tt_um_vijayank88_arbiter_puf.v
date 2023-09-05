`default_nettype none

module tt_um_vijayank88_arbiter_puf (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7-segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
    
);

	`ifdef USE_POWER_PINS
   	 inout vccd1,    // User area 1 1.8V power
   	 inout vssd1     // User area 1 digital ground
	`endif    
	
    
    // Declare internal signals
wire ipulse = clk;                    // Define signals to connect
wire [7:0] ichallenge;
wire oresponse;

// Assignments
assign oresponse = uo_out[7];   // Connect arbiterpuf response to uo_out[7]
assign ichallenge[7:0] = uio_in[7:0];      // Connect ichallenge to uio_in
    
    arbiterpuf arb_inst (
        `ifdef USE_POWER_PINS
        .vccd1(vccd1),
        .vssd1(vssd1),
        `endif
        .ipulse(ipulse),
        .ichallenge(ichallenge),
        .oresponse(oresponse)
    );
  
endmodule
	
//`timescale 1ns / 1ps
//`include "timescale.vh"
module arbiterpuf(
`ifdef USE_POWER_PINS
	inout vccd1,	// User area 1 1.8V power
	inout vssd1,	// User area 1 digital ground
`endif
	input ipulse,
	input[7:0] ichallenge,
	output oresponse
    );
    wire odelay_line_oout_1;
    wire odelay_line_oout_2;
    
    delay_line inst_delay_line (
    .ipulse(ipulse),
    .ichallenge(ichallenge),
    .oout_1(odelay_line_oout_1),
    .oout_2(odelay_line_oout_2)
    );
    dff inst_dff1(
    .id(odelay_line_oout_2),
    .iclk(odelay_line_oout_1),
    .oq(oresponse)
    );
    
endmodule
module mux(
    input ia,
    input ib,
    input isel,
    output reg oout
    );
     always@(*)
         oout <= isel ? ia : ib;
endmodule
module dff(
    input id,
    input iclk,
    output reg oq
    );
    
    always @ (posedge iclk)  
    begin 
   oq <= id;
   end
endmodule

`ifndef parameters
`define  parameters

 parameter C_LENGTH = 8; //the length of the chain of the multiplexer 
`endif 

module delay_line(
//input ipulse,isel,
//output oout
input ipulse,
input [C_LENGTH - 1 : 0] ichallenge,
output oout_1,
output oout_2
    );

    (* dont_touch = "yes" *) wire  [2 * C_LENGTH + 1 : 0] net;
 //   wire [2 * C_LENGTH + 1 : 0] net;
    assign net [0] =ipulse;
    assign net [1] = ipulse;
    generate
    genvar i;
    for (i =1; i <= C_LENGTH; i = i +1)
    begin
    mux inst_mux_1(
    .ia(net[i *2 -2]),
    .ib(net[i *2 -1]),
    .isel(ichallenge[i-1]),
    .oout(net[i *2])
    );
     mux inst_mux_2(
    .ia(net[i *2 - 1]),
    .ib(net[i *2 -2]),
    .isel(ichallenge[i - 1]),
    .oout(net[i * 2 +1])
    );
    end
           
    endgenerate
    
    assign oout_1 = net [C_LENGTH * 2];
    assign oout_2 = net [C_LENGTH * 2 + 1];
    endmodule
