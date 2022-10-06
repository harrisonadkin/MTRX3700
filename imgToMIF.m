%% Run this script to prepare your own image for flashing onto the FPGA's block RAM.
% .mif : Memeory Initiation File, an ascii description listing the memory contents at each address.

%%% ------------------- PUT YOUR IMAGE FILENAME IN THE NEXT LINE: --------------------
img=imread('Mountain.png'); % Input image: 320x240 24-bit BMP image RGB888 
%%% ----------------------------------------------------------------------------------

assert(all(size(img)==[240 320 3]), "Please ensure the input image is 320x240 pixels, RGB!")
[HEIGHT WIDTH nC] = size(img);
num_colours = 256;

colours = colorcube(num_colours); % Creates a colour table of colours
img_reduced = rgb2ind(img,colours); % Reduces the colours in the image to the 256 colours generated in the colour table above.
% This is to reduce the memory required by the image such that it fits into the FPGA's available block RAM.

index_file = fopen("img_index.mif",'w');  % The index file contains a look up table 'colour-table' that associates 24-bit colour values for a given index.
img_file = fopen("img_data.mif",'w');     % The image file contains each pixel of the image as a sequence of 8-bit 'colour-table' indexes in row-major order.

% Start writing the index file (this is all just .mif syntax):
fprintf(index_file, "WIDTH=24;\n");  % Data width of this RAM is 24-bits
fprintf(index_file, "DEPTH=%d;\n",num_colours); % The RAM has n'um_colours' amount of 24-bits
fprintf(index_file, "ADDRESS_RADIX = HEX;\n");
fprintf(index_file, "DATA_RADIX = HEX;\n");
fprintf(index_file, "CONTENT BEGIN\n");
for i = 1:num_colours
    fprintf(index_file, "%x:%.2x%.2x%.2x;\n",(i-1),floor(colours(i,1)*255),floor(colours(i,2)*255),floor(colours(i,3)*255));  % Print the 24-bit colour value for each index.
end
fprintf(index_file, "END;");
fclose(index_file);

% Start writing the image file (this is all just .mif syntax):
fprintf(img_file, "WIDTH=8;\n"); % Data width of this RAM is 8-bits
fprintf(img_file, "DEPTH=%d;\n",WIDTH*HEIGHT); % The RAM has a byte for each pixel in the image.
fprintf(img_file, "ADDRESS_RADIX = HEX;\n");
fprintf(img_file, "DATA_RADIX = HEX;\n");
fprintf(img_file, "CONTENT BEGIN\n");
for i=1:HEIGHT
    for j=1:WIDTH
        index = img_reduced(i,j);
        fprintf(img_file, "%x:%.2x;\n", (i-1)*WIDTH+(j-1), index);  % Print the 8-bit 'colour-table' index for each pixel in the image.
    end
end
fprintf(img_file, "END;");
fclose(img_file);