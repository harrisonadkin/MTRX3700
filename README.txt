Add all Verilog files in this folder to your Quartus project.

'Q3.v' is the top-entity module for Q3.
Make sure to compile with 'Q3' set as the top-level entity in the project settings.

1. First, try compiling the code and displaying the demo image onto the VGA monitor (ensure you connect the VGA cable from the board to the monitor).
2. Next, try replacing the default image with your own, by generating new 'img_index.mif' and 'img_data.mif' files using the imgToMIF.m MATLAB script (check for the line with the input image filename).
3. Open 'filter.v'. This is the part you must implement. Currently, this module is simply passing the input 24-bit RGB pixels to the output with no filtering.
4. Write the code for parts a), b) and c). Note that you will have to modify the input ports of the filter module in both "filter.v" and "Q3.v" to use the switches as inputs. Comment out code that you no longer need from previous parts.
5. Instructions for part d). will be     at a later date as a separate document.