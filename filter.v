module filter(input clk, reset, input [23:0] data_in, input [17:0] SW,
              output [23:0] out);
				  
// -------- variables -------- //
reg [23:0] inv_filter;

// ---
integer hold_red = 0;
integer hold_green = 0;
integer hold_blue = 0;
reg [23:0] bri_filter;
reg [3:0] scale_fac = 1.0;

// ---
reg [23:0] thres_filter;
reg [23:0] intensity;
integer threshold = 0;

// ---
reg [23:0] conv_filter;
integer kernel[8:0];
integer x[8:0];
integer i = 0;
 
reg [23:0] buffer1 [639:0];
reg [23:0] buffer2 [639:0];
reg [23:0] buffer3 [639:0];


// ---



// -------- inverter -------- //
/*
always@(*) 
	inv_filter = ~data_in;

assign out = {inv_filter[23:16], inv_filter[15:8], inv_filter[7:0]}; // Replace this to output the desired filtered 24-bit RGB bit vector.
*/

// -------- brightness -------- //
/*
always@(*)
begin	
	//luminance = (0.2126*data_in[23:16] + 0.7152*data_in[15:8] + 0.0722*data_in[7:0]);
	case(SW)
	
	1:begin
			hold_red = data_in[23:16] * 5;
			hold_green = data_in[15:8] * 5;
			hold_blue = data_in[7:0] * 5;
	end
	
	3:begin
			hold_red = data_in[23:16] * 4;
			hold_green = data_in[15:8] * 4;
			hold_blue = data_in[7:0] * 4;
	
	end
	
	7:begin
			hold_red = data_in[23:16] * 3;
			hold_green = data_in[15:8] * 3;
			hold_blue = data_in[7:0] * 3;
	
	end
	
	15:begin
			hold_red = data_in[23:16] * 2;
			hold_green = data_in[15:8] * 2;
			hold_blue = data_in[7:0] * 2;
	
	end
	
	31:begin
			hold_red = data_in[23:16] * 1;
			hold_green = data_in[15:8] * 1;
			hold_blue = data_in[7:0] * 1;
	
	end
	
	63:begin
			hold_red = data_in[23:16] /2 ;
			hold_green = data_in[15:8] /2;
			hold_blue = data_in[7:0] /2;
	
	end
	
	127:begin
			hold_red = data_in[23:16] /4;
			hold_green = data_in[15:8] /4;
			hold_blue = data_in[7:0] /4;
	
	end
	
	255:begin
			hold_red = data_in[23:16] /8;
			hold_green = data_in[15:8] /8;
			hold_blue = data_in[7:0] /8;
	
	end
	endcase

	

	if(hold_red > 255)
		bri_filter[23:16] = 255;
		
	else if(hold_red < 0)
		bri_filter[23:16] = 0;
	
	else
		bri_filter[23:16] = hold_red;
	
	
	if(hold_green > 255)
		bri_filter[15:8] = 255;
	else if(hold_green < 0)
		bri_filter[15:8] = 0;
	else
		bri_filter[15:8] = hold_green;
		
	if(hold_blue > 255)
		bri_filter[7:0] = 255;
	else if(hold_blue < 0)
		bri_filter[7:0] = 0;
	else 
		bri_filter[7:0] = hold_blue;
	
end
		
assign out = {bri_filter[23:16], bri_filter[15:8], bri_filter[7:0]};

endmodule
*/
// -------- thresholding -------- //
/*
always@(*) 
begin
	intensity = (data_in[23:16] + data_in[15:8] + data_in[7:0]) / 3;
	case(SW)
	
	1:begin
			threshold = 32;
	end
	
	3:begin
			threshold = 64;
	
	end
	
	7:begin
			threshold = 96;
	
	end
	
	15:begin
			threshold = 128;
	
	end
	
	31:begin
			threshold = 160;
	
	end
	
	63:begin
			threshold = 192;
			
	end
	
	127:begin
			threshold = 224;
	
	end
	
	255:begin
			threshold = 255;
	
	end
	endcase
	
	
	
	if ( intensity >= threshold )
		begin
		thres_filter[23:16] = 255; 
		thres_filter[15:8] = 255;
		thres_filter[7:0] = 255;
		end
	else
		begin 
		thres_filter[23:16] = 0; 
		thres_filter[15:8] = 0;
		thres_filter[7:0] = 0;
		end
end	
assign out = {thres_filter[23:16], thres_filter[15:8], thres_filter[7:0]}; // Replace this to output the desired filtered 24-bit RGB bit vector.


endmodule
*/
// ------- convolution -------- //

ram_2_port my_fram (
	.clock(clk));
	//.data(), // what we write the data to
	//.rdaddress(),
	//.wraddress(),
	//.wren(),
	//.q()); // read data

always@(*)
begin
	
	case(SW)
	1:begin
		kernel[0] = 0; kernel[1] = -1; kernel[2] = 0;
		kernel[3] = -1; kernel[4] = 5; kernel[5] = -1;
		kernel[6] = 0; kernel[7] = -1; kernel[8] = 0;
	end
	
	3:begin
		kernel[0] = 1; kernel[1] = 2; kernel[2] = 1;
		kernel[3] = 2; kernel[4] = 4; kernel[5] = 2;
		kernel[6] = 1; kernel[7] = 2; kernel[8] = 1;
	end
	
	7:begin
		kernel[0] = -1; kernel[1] = -1; kernel[2] = -1;
		kernel[3] = -1; kernel[4] = 8; kernel[5] = -1;
		kernel[6] = -1; kernel[7] = -1; kernel[8] = -1;
	end

	endcase

end

always@(clk)
begin // need to push each row into the storage registers, pop final 3, multiply by kernel add, do for two more rows and add total then push final to my_fram
	buffer1[0] <= data_in;
	buffer2[0] <= buffer1[639];
	buffer3[0] <= buffer2[639];
	for ( i = 0; i < 639; i = i + 1 )
		begin
			
		buffer1[i+1] <= buffer1[i];
		buffer2[i+1] <= buffer2[i];
		buffer3[i+1] <= buffer3[i]; // note non blocking operations happen instantaneously-ish on clock rising edge 
		
		/*x[0] <= buffer1[i-1];
		x[1] <= buffer1[i];
		x[2] <= buffer1[i+1];
		x[3] <= buffer2[i-1];
		x[4] <= buffer2[i];
		x[5] <= buffer2[i+1];
		x[6] <= buffer3[i-1];
		x[7] <= buffer3[i];
		x[8] <= buffer3[i+1];
		*/
		
		end
	
		

end

//assign out = {};
endmodule




/*
 * Kernels (For Q3 d).) See https://en.wikipedia.org/wiki/Kernel_(image_processing) 
 *  
 * Sharpen:
 * | 0 -1  0|
 * |-1  5 -1|
 * | 0 -1  0|
 *
 * Gaussian Blur:
 *  1   |1  2  1|
 *  —   |2  4  2|
 *  16  |1  2  1|
 *
 * Ridge Detection:
 * |-1 -1 -1|
 * |-1  8 -1|
 * |-1 -1 -1|
 */
