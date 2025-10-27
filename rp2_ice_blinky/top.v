	///////////////////////////////////////////////////////////////////////////////
	// This module is used to debounce any switch or button coming into the FPGA.
	// Does not allow the output of the switch to change unless the switch is
	// steady for enough time (not toggling).
	///////////////////////////////////////////////////////////////////////////////
	module Debounce_Switch (input i_Clk, input i_Switch, output o_Switch);
	
	parameter c_DEBOUNCE_LIMIT = 250000;  // 10 ms at 25 MHz
	
	reg [17:0] r_Count = 0;
	reg r_State = 1'b0;
	
	always @(posedge i_Clk)
	begin
		// Switch input is different than internal switch value, so an input is
		// changing.  Increase the counter until it is stable for enough time.  
		if (i_Switch !== r_State && r_Count < c_DEBOUNCE_LIMIT)
		r_Count <= r_Count + 1;
	
		// End of counter reached, switch is stable, register it, reset counter
		else if (r_Count == c_DEBOUNCE_LIMIT)
		begin
		r_State <= i_Switch;
		r_Count <= 0;
		end 
	
		// Switches are the same state, reset the counter
		else
		r_Count <= 0;
	end
	
	// Assign internal register to output (debounced!)
	assign o_Switch = r_State;
	
	endmodule

	module top (
	    input  clock,              	// clock
	    input  ICE_28,      	   	// button for counting up
	    input  ICE_32,     	       	// button for counting down
	    output [3:0] display  	// 4-bit output count (0-15)
	);

	  reg  r_Switch_u;				 // previous state of up switch
    wire w_Switch_u;			   	// debounced up switch

	  reg  r_Switch_d;			   	// previous state of down switch
	  wire w_Switch_d;			   	// debounced down switch

	  reg [3:0] count;			   	// internal count register

	  // Instantiate debounce Switches
	  Debounce_Switch Debounced_Inst_U (
		.i_Clk(clock),
		.i_Switch(ICE_28),
		.o_Switch(w_Switch_u)
	  );

	  Debounce_Switch Debounced_Inst_D (
		.i_Clk(clock),
		.i_Switch(ICE_32),
		.o_Switch(w_Switch_d)
	  );
   
   
	    always @(posedge clock) begin
        r_Switch_d <= w_Switch_d;
        r_Switch_u <= w_Switch_u;

        if (w_Switch_u == 1'b0 && r_Switch_u == 1'b0)
          count <= (count[3:0] == 4'b1111) ? 4'b0 : count + 1;    // count up (mod 16)
        else if (w_Switch_d == 1'b0 && r_Switch_d == 1'b0)
          count <= (count[3:0] == 4'b0) ? 4'b1111 : count - 1;  // count down (mod 16)
        else count = count;
	    end
      assign display[3:0] = count[3:0];

	endmodule
