% This is free and unencumbered software released into the public domain.

% Anyone is free to copy, modify, publish, use, compile, sell, or
% distribute this software, either in source code form or as a compiled
% binary, for any purpose, commercial or non-commercial, and by any
% means.

% In jurisdictions that recognize copyright laws, the author or authors
% of this software dedicate any and all copyright interest in the
% software to the public domain. We make this dedication for the benefit
% of the public at large and to the detriment of our heirs and
% successors. We intend this dedication to be an overt act of
% relinquishment in perpetuity of all present and future rights to this
% software under copyright law.

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
% OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
% OTHER DEALINGS IN THE SOFTWARE.

% For more information, please refer to <https://unlicense.org>

% This is example of creating an Epson ACCL RPI object, configuring the device, 
% capturing sensor data, printing the scaled sensor data to console,
% and plotting to graph

% These examples assumes the following pinmapping:
%  Epson Device                Raspberry Pi
%  ---------------------------------------------------
%  EPSON_RESET                 RPI_GPIO_P1_15 (GPIO22) 
%  EPSON_DRDY                  RPI_GPIO_P1_18 (GPIO24)
%  EPSON_CS                    RPI_GPIO_P1_24 (GPIO08)/CE0
%  SPI_SCK                     RPI_GPIO_P1_23 (GPIO11)
%  SPI_MISO                    RPI_GPIO_P1_21 (GPIO9)
%  SPI_MOSI                    RPI_GPIO_P1_19 (GPIO10)

% Clear workspace
clear;

% Specify # of samples to capture
NUM_OF_SAMPLES = 1000;

% Create Epson Device RPI Object
% Specify SpiClockspeed, Reset pin, DRDY pin as needed based on
% Raspberry Pi configuration and connection to device
% i.e. e = A352Accl(SpiClkInHz, PinReset, PinDRDY);
% 
% The default if not specified is:
% SpiClkInHz = 1000000
% PinReset = 22
% PinDrdy = 24
e = A352Accl();  % For A352AD10 (speed=1000000, reset=22, drdy=24)

% Configure the Epson Accelerometer settings by modifying properties
% as needed
% i.e. e.Property = value;
e.Ndflag = 1;   % Enable NDFLAG in the burst
e.TempC = 1;    % Enable TempC in the burst
e.Chksm16 = 1;  % Enable CHKSM16 in the burst
e.ReducedNoiseEn = 1; % Enable Reduced Noise Floor mode
e.DoutRate = 100; % Set output rate at 100Hz
e.FilterSel = '512fc9'; % Set filter Tap=512 Fcutoff=9Hz

% Initialize Epson ACCL registers with properties
e.setDeviceCfg();

% Capture scaled samples into an array
capture = e.getScaledSamples(NUM_OF_SAMPLES);

% Print Scaled Data in Tabular output
e.printTabular(capture);

%Plot
start_col = 1 + e.Ndflag + (e.TempC ~= 0);
createAcclPlot(capture.samples(:,start_col:start_col+2));
%end