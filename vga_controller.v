module vga_controller(iRST_n,
                      iVGA_CLK,
							 iRGB_data,
							 oAddress,
                      oBLANK_n,
                      oHS,
                      oVS,
                      b_data,
                      g_data,
                      r_data);
input iRST_n;
input iVGA_CLK;
input [23:0] iRGB_data;
output [18:0] oAddress;
output reg oBLANK_n;
output reg oHS;
output reg oVS;
output [7:0] r_data;  
output [7:0] g_data; 
output [7:0] b_data;                       
///////// ////       
              
reg [16:0] ADDR, last_ADDR_v;
reg ADDR_repeat_h;
reg ADDR_repeat_v;
reg cHS_changed;
assign oAddress=ADDR;
reg [23:0] rgb_data;

wire cBLANK_n,cHS,cVS,rst;
////
assign rst = ~iRST_n;

video_sync_generator LTM_ins (.vga_clk(iVGA_CLK),
                              .reset(rst),
                              .blank_n(cBLANK_n),
                              .HS(cHS),
                              .VS(cVS));
										
//////Addresss generator (includes nearest-neighbour upscaling by x2 to convert input resolution 320x240 to output resolution 640x480)
always@(posedge iVGA_CLK,negedge iRST_n)
begin
  if (!iRST_n)                            // Reset condition
  begin
     ADDR<=17'd0;
	  ADDR_repeat_h <= 0;
	  ADDR_repeat_v <= 0;
	  last_ADDR_v <= 0;
	  cHS_changed <= 0;
  end
  else if (cHS==1'b0 && cVS==1'b0)        // Both horizontal sync and vertical sync are *active low*; this condition signifies the end of the frame. Reset the address.
  begin
     ADDR<=17'd0;
	  ADDR_repeat_h <= 0;
	  ADDR_repeat_v <= 0;
	  last_ADDR_v <= 0;
	  cHS_changed <= 0;
  end
  else if (cHS==1'b0) cHS_changed <= 1'b1;   // Horizontal sync is active; this condition signifies the end of the horizontal line. Flag that cHS has changed.
  else if (cHS==1'b1 && cHS_changed==1'b1)   // Horizontal sync is inactive, but just changed from active. Thus it has just risen. This is an edge trigger.
  begin
     cHS_changed <= 1'b0;                    // Reset the cHS changed flag. We now know that we are at the end of the line.
     if (!ADDR_repeat_v)                     // (Vertical 2x upscaling) Check if the line has been repeated yet
	  begin
			ADDR<=last_ADDR_v;                  // Not repeated yet: set address to the beginning of the line again
			ADDR_repeat_v <= 1;
	  end
	  else
	  begin
	      ADDR_repeat_v <= 0;                 // Yes repeated: don't change address (yet), store the new beginning of the line
			last_ADDR_v <= ADDR;
	  end
  end
  else if (cBLANK_n==1'b1)                   // This condition means that the controller is currently writing pixel data (i.e. in the active display region)
     if (!ADDR_repeat_h) ADDR_repeat_h <= 1; // (Horizontal 2x upscaling) Check if this pixel has been repeated yet
	  else begin
		  ADDR_repeat_h = 0;	                  // Yes repeated: increment the address to the next pixel.
		  ADDR<=ADDR+1;                        // Whilst the VGA is being fed pixel data, increase the address to progress to the next pixel for the next clock cycle.
   end
end


//////latch valid data at falling edge;
always@(negedge iVGA_CLK) rgb_data <= iRGB_data;


assign b_data = rgb_data[23:16];
assign g_data = rgb_data[15:8];
assign r_data = rgb_data[7:0];
///////////////////
//////Delay the iHD, iVD,iDEN for one clock cycle;
always@(negedge iVGA_CLK)
begin
  oHS<=cHS;
  oVS<=cVS;
  oBLANK_n<=cBLANK_n;
end

endmodule
 	
















