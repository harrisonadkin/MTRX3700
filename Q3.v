module Q3(
	/////////////CLOCKS//////////
   input                      CLOCK_50,
	input                      CLOCK2_50,
	/////////////USER///////////
	input           [3:0]       KEY,
	input           [17:0]      SW,
	//////////// VGA //////////
	output	      [7:0]		VGA_R,
	output		   [7:0]		VGA_B,
	output		   [7:0]		VGA_G,
	output		        		VGA_BLANK_N,
	output	         		VGA_SYNC_N,
	output		        		VGA_CLK,
	output	          		VGA_HS,
	output	          		VGA_VS
);

wire		   VGA_CTRL_CLK;                      // VGA clock (25MHz, which is close enough to the 640x480 resolution VGA standard).
wire		   DLY_RST;                           // Reset (is held active for a small delay at start up).

wire [16:0] vga_addr;                          // Pixel address (row-major order) of the image source ROM that the VGA is currently reading from.
wire [7:0] colour_index;                       // Index of the current colour being read from the colour look-up table.
 
wire filter_en;                                // Filter enable
wire [23:0] read_data, pixel_data, filter_out; // 24-bit pixel data wires

/////// Switch SW0 on to enable the filter:
assign filter_en = SW[0];  
assign read_data = filter_en ? filter_out : pixel_data;

////// Reset Delay (from Q2.1)
Reset_Delay	    r0	(.iCLK(CLOCK_50), .oRESET(DLY_RST));

////// VGA Phase-locked loop (PLL) generates a 25 MHz clock 'VGA_CTRL_CLK' from the main 50 MHz clock.
VGA_PLL         p1	(.areset(~DLY_RST), .inclk0(CLOCK2_50), .c0(VGA_CTRL_CLK));

////// Image data ROM (stores the 320x240 source image in the form of 8-bit colour indexes. Outputs the colour index for a given pixel address):
img_data	#(.WIDTH(320), .HEIGHT(240))
                img_data_inst (
	             .address ( vga_addr ),
	             .clock ( ~VGA_CTRL_CLK ),
	             .q ( colour_index )
	             );
	
////// Color table ROM (Stores the 256 colours used in the image. Outputs the 24-bit colour for the given colour-index):
img_index	    img_index_inst (
	             .address ( colour_index ),
	             .clock ( VGA_CTRL_CLK ),
	             .q ( pixel_data)
	             );						 

////// Filter: ***This is the code you are to change. See filter.v***
filter          f0(
                .clk(VGA_CTRL_CLK), 
                .reset(DLY_RST),
				    .data_in(pixel_data),
					 .SW(SW),
	             .out(filter_out)
				    );

////// VGA controller (outputs 640x480 VGA signal):
// This controller includes a nearest-neighbor upscaling to convert the 320x240 source image into 640x480.
assign VGA_CLK = VGA_CTRL_CLK;
vga_controller vga_ins (
               .iRST_n(DLY_RST),
               .iVGA_CLK(VGA_CTRL_CLK),
               .iRGB_data(read_data), // 
               .oAddress(vga_addr),      // The VGA controller decides what pixel address to read
               .oBLANK_n(VGA_BLANK_N),   // High when the output is valid pixel data
               .oHS(VGA_HS),             // Horizontal Sync (active low)
               .oVS(VGA_VS),             // Vertical Sync   (active low)
               .b_data(VGA_B),           // Blue channel
               .g_data(VGA_G),           // Green channel
               .r_data(VGA_R)            // Red channel
				   );			  

endmodule
