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

% This is example of creating an Epson IMU RPI object, configuring the device, 
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
% i.e. e = GxxxImu(SpiClkInHz, PinReset, PinDRDY);
% 
% The default if not specified is:
% SpiClkInHz = 1000000
% PinReset = 22
% PinDrdy = 24

% Latest models
%%%%%%%%%%%%%%%%
e = G330_G366Imu();  % For G330PDG0 or G366PDG0 (speed=1000000, reset=22, drdy=24)
%e = G365Imu;  % For G365PDF1 (speed=1000000, reset=22, drdy=24)
%e = G365Imu(1000000, 22, 24, 1);  % For G365PDC1 (speed=1000000, reset=22, drdy=24, IsPDC1=1)
%e = G370F_G370SImu();  % For G370PDF1 (speed=1000000, reset=22, drdy=24)
%e = G370F_G370SImu(1000000, 22, 24, 1);  % For G370PDS0 (speed=1000000, reset=22, drdy=24, isPDS0=1)
%e = G370G_G370TImu();  % For G370PDG0 (speed=1000000, reset=22, drdy=24)
%e = G370G_G370TImu(1000000, 22, 24, 1);  % For G370PDT0 (speed=1000000, reset=22, drdy=24 IsPDT0=1)

% Legacy models
%%%%%%%%%%%%%%%
%e = G320Imu();  % For G320 (speed=1000000, reset=22, drdy=24)
%e = G354Imu();  % For G354 (speed=1000000, reset=22, drdy=24)
%e = G364Imu();  % For G364PDC0 (speed=1000000, reset=22, drdy=24)
%e = G364Imu(1000000, 22, 24, 1);  % For G364PDCA (speed=1000000, reset=22, drdy=24, IsPDCA=1)

% Configure the Epson IMU settings by modifying properties
% as needed
% i.e. e.Property = value;
e.Ndflag = 1;   % Enable NDFLAG in the burst
e.TempC = 1;  % Enable TEMPC 16-bit in the burst
e.Gyro = 2;  % Enable GYROXYZ 32-bit in the burst
e.Accl = 2;  % Enable ACCLXYZ 32-bit in the burst
e.DeltaA = 0;  % Disable DLTAXYZ in the burst
e.DeltaV = 0;  % Disable DLTVXYZ in the burst
e.Gpio = 0;  % Disable GPIO in the burst
e.Counter = 1;  % Enable COUNTER in the burst
e.Chksm16 = 1;  % Enable CHKSM16 in the burst
e.DoutRate = 125; % Set output rate at 125Hz
e.FilterSel = 'tap32'; % Set filter moving average tap=32

% Properties only supported by G365, G330, G366
%e.Atti = 1;  % Enable Euler ANG123 16-bit in the burst
%e.Quaternion = 1;  % Enable QTN0123 16-bit in the burst

% Properties only supported by G330, G366, G370PDG0, G370PDT0
%e.Set16G = 1;  % Enable 16G range on accelerometers (A_RANGE)

% Initialize Epson IMU registers with properties
e.setDeviceCfg();

% Capture scaled samples into an array
capture = e.getScaledSamples(NUM_OF_SAMPLES);

% Print Scaled Data in Tabular output
e.printTabular(capture);

%Plot
start_col = 1 + e.Ndflag + (e.TempC ~= 0);
createGyroPlot(capture.samples(:,start_col:start_col+2));
createAcclPlot(capture.samples(:,start_col+3:start_col+5));
%end