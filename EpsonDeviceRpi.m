% Disclaimer:
% --------------
% THE SOFTWARE IS RELEASED INTO THE PUBLIC DOMAIN.
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
% INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, NONINFRINGEMENT,
% SECURITY, SATISFACTORY QUALITY, AND FITNESS FOR A PARTICULAR PURPOSE.
% IN NO EVENT SHALL EPSON BE LIABLE FOR ANY LOSS, DAMAGE OR CLAIM, ARISING FROM OR
% IN CONNECTION WITH THE SOFTWARE OR THE USE OF THE SOFTWARE.
%
% Epson Device RPI handle class represents basic RPI-SPI object
% with properties and methods to communicate with the device connected
% to Raspberry Pi SPI interface

classdef EpsonDeviceRpi < handle

    properties
        Ndflag (1,1) {mustBeInteger, ... % Enable NDFLAG field in burst sample
            mustBeNonnegative, mustBeLessThan(Ndflag, 2)} = 1;
        TempC (1,1) {mustBeInteger, ... % TempC field 0=Disable, 1=Enable 16-bit , 2=Enable 32
            mustBeNonnegative, mustBeLessThan(TempC, 3)} = 1;
        Counter (1,1) {mustBeInteger, ... % Enable COUNT field in burst sample
            mustBeNonnegative, mustBeLessThan(Counter, 2)} = 1;
        Chksm16 (1,1) {mustBeInteger, ... % Enable CHKSM field in burst sample
            mustBeNonnegative, mustBeLessThan(Chksm16, 2)} = 1;
    end

    properties(GetAccess = 'public' , SetAccess = 'protected')
        Sampling (1,1) {mustBeInteger, ... % Status indicating SAMPLING mode status
            mustBeNonnegative, mustBeLessThan(Sampling, 2)};
        BytesPerBurst (1,1) {mustBeInteger, ... % Status indicating # of bytes per burst sample
            mustBeNonnegative, mustBeLessThan(BytesPerBurst, 74)};
        FieldsPerBurst (1,1) {mustBeInteger, ... % Status indicating # of fields per burst sample
            mustBeNonnegative, mustBeLessThan(FieldsPerBurst, 21)};
        FieldsInBurst = []; % Status indicating fields in burst sample
        RpiPinReset (1,1) uint8 {mustBeInteger, mustBeNonnegative, ...
            mustBeMember(RpiPinReset, [2 3 4 14 15 ...
                17 18 22 23 24 25 27])} = 22; % RPI output pin connected to device RESET#
        RpiPinDrdy (1,1) uint8 {mustBeInteger, mustBeNonnegative, ...
            mustBeMember(RpiPinDrdy, [2 3 4 14 15 ...
                17 18 22 23 24 25 27])} = 24; % RPI input pin connected to device DRDY
        RpiSpiSpeedHz (1,1) uint32 {mustBeInteger, ... % RPI SPI clock speed in Hz
            mustBeNonnegative, mustBeLessThan(RpiSpiSpeedHz, 1000001)} = 1000000;
        Sensor; % handle to Sensor SPI object
        rpi; % handle to Raspberry Pi object
    end

    properties(Constant, Hidden=true)
        % Register Addresses
        MODE_CTRL = [0, hex2dec('02')];
        DIAG_STAT = [0, hex2dec('04')];
        FLAG = [0, hex2dec('06')];
        COUNT = [0, hex2dec('0A')];
        ID = [0, hex2dec('4C')];

        SIG_CTRL = [1, hex2dec('00')];
        MSC_CTRL = [1, hex2dec('02')];
        SMPL_CTRL = [1, hex2dec('04')];
        FILTER_CTRL = [1, hex2dec('06')];
        UART_CTRL = [1, hex2dec('08')];
        GLOB_CMD = [1, hex2dec('0A')];
        PROD_ID1 = [1, hex2dec('6A')];
        PROD_ID2 = [1, hex2dec('6C')];
        PROD_ID3 = [1, hex2dec('6E')];
        PROD_ID4 = [1, hex2dec('70')];
        VERSION = [1, hex2dec('72')];
        SER_NUM1 = [1, hex2dec('74')];
        SER_NUM2 = [1, hex2dec('76')];
        SER_NUM3 = [1, hex2dec('78')];
        SER_NUM4 = [1, hex2dec('7A')];
        WIN_CTRL = [0, hex2dec('FE')];

        % SPI
        SER_TYPE = 'spi'; % Only SPI is supported
        CS = 'CE0'; % Only SPI_CS0 is supported
        SPI_MODE = 3; % Only SPI Mode3 supported

        % Device Timings
        TSTALL = 20e-6;
        TSTALL1 = 45e-6;
        RESET_ACTIVE = 100e-3;
        RESET_DELAY = 800e-3;
        GOTO_CONFIG_DELAY = 100e-3;
        NOTREADY_DELAY = 100e-3;
    end

    methods

        function obj = EpsonDeviceRpi(speed, pin_reset, pin_drdy)
        % class constructor
            if exist('speed', 'var')
                obj.RpiSpiSpeedHz = speed;
            end
            if exist('pin_reset', 'var')
                obj.RpiPinReset = pin_reset;
            end
            if exist('pin_drdy', 'var')
                obj.RpiPinDrdy = pin_drdy;
            end
            obj.rpi = raspi();
            obj.Sensor = obj.rpi.spidev(obj.CS, ...
                obj.SPI_MODE, obj.RpiSpiSpeedHz);
            % dummy SPI cycle, precaution to get pin states of SPI IF normal
            obj.Sensor.writeRead([hex2dec('02') hex2dec('00')]);
            % assign RPI GPIOs to IMU IF RESET & DRDY pins
            obj.assignGpios();
            % toggle HW reset, power-on sequence, get device info
            obj.resetDevice();
            obj.powerOn();
            obj.getModel();
            obj.getVersion();
            obj.getSerialId();
        end

        function resetDevice(obj)
        % Toggle HW Reset and wait 800 msec
            writeDigitalPin(obj.rpi, obj.RpiPinReset, 0);
            pause(obj.RESET_ACTIVE);
            writeDigitalPin(obj.rpi, obj.RpiPinReset, 1);
            pause(obj.RESET_DELAY);
            fprintf('\nToggle RESET#\n');
            valID = obj.readReg(obj.ID);
            if ~isequal(valID, uint8([83 69]))
                fprintf('Cannot communicate with sensor device');
                error('Check hardware connection of the sensor device');
            end
        end

        function writeRegH(obj, regArray, writeByte, verbose)
        % Write to HIGH byte of specified WIN_ID & register address
        % address must be an even integer value less than 127
            if ~exist('verbose', 'var')
                verbose = 0;
            end
            win_id = regArray(1);
            % OR the address with 0x80
            reg_addr_ = bitor(uint8(regArray(2)), hex2dec('80'));
            % Set WIN_ID
            obj.Sensor.writeRead([obj.WIN_CTRL(2) win_id]);
            % tSTALL
            pause(obj.TSTALL);
            % Write Byte to Address
            obj.Sensor.writeRead([reg_addr_+1 writeByte]);
            % tSTALL
            pause(obj.TSTALL);
            if verbose
                fprintf('REG[0x%02x (W%0x)] < 0x%02x\n', regArray(2)+1,...
                    win_id, writeByte);
            end
        end

        function writeRegL(obj, regArray, writeByte, verbose)
        % Write to LOW byte of specified WIN_ID & register address
        % address must be an even integer value less than 127
            if ~exist('verbose', 'var')
                verbose = 0;
            end
            win_id = regArray(1);
            % OR the address with 0x80
            reg_addr_ = bitor(uint8(regArray(2)), hex2dec('80'));
            % Set WIN_ID
            obj.Sensor.writeRead([obj.WIN_CTRL(2) win_id]);
            % tSTALL
            pause(obj.TSTALL);
            % Write Byte to Address
            obj.Sensor.writeRead([reg_addr_ writeByte]);
            % tSTALL
            pause(obj.TSTALL);
            if verbose
                fprintf('REG[0x%02x (W%0x)] < 0x%02x\n', regArray(2),...
                    win_id, writeByte);
            end
        end

        function retval = readReg(obj, regArray, verbose)
        % Read a 16-bit value from specified WIN_ID & register address
        % address must be an even integer value less than 127
            if ~exist('verbose', 'var')
                verbose = 0;
            end
            win_id = regArray(1);
            % AND the address with 0x7E
            reg_addr_ = bitand(uint8(regArray(2)), hex2dec('7E'));
            % Set WIN_ID
            obj.Sensor.writeRead([obj.WIN_CTRL(2) win_id]);
            % tSTALL
            pause(obj.TSTALL);
            % Read 16-bit from Address
            obj.Sensor.writeRead([reg_addr_ 0]);
            % tSTALL
            pause(obj.TSTALL);
            retval = obj.Sensor.writeRead([0 0]);
            % tSTALL
            pause(obj.TSTALL);
            if verbose
                fprintf('REG[0x%02x (W%0x)] > 0x%02x%02x\n', reg_addr_,...
                    win_id, retval(1), retval(2));
            end
        end

        function retval = getModel(obj)
        % Read back MODEL number
            x1 = obj.readReg(obj.PROD_ID1);
            x2 = obj.readReg(obj.PROD_ID2);
            x3 = obj.readReg(obj.PROD_ID3);
            x4 = obj.readReg(obj.PROD_ID4);
            retval = [x1(2) x1(1) x2(2) x2(1) x3(2) x3(1) x4(2) x4(1)];
            fprintf('Model: %s\n', native2unicode(retval, 'US-ASCII'));
        end

        function retval = getVersion(obj)
        % Read back VERSION number
            x1 = obj.readReg(obj.VERSION);
            retval = x1;
            fprintf('Version: %s.%s\n', string(retval));
        end

        function retval = getSerialId(obj)
        % Read back SERIAL_NUM
            x1 = obj.readReg(obj.SER_NUM1);
            x2 = obj.readReg(obj.SER_NUM2);
            x3 = obj.readReg(obj.SER_NUM3);
            x4 = obj.readReg(obj.SER_NUM4);
            retval = [x1(2) x1(1) x2(2) x2(1) x3(2) x3(1) x4(2) x4(1)];
            fprintf('Serial#: %s\n', native2unicode(retval, 'US-ASCII'));
        end

        function gotoSampling(obj)
        % Go to SAMPLING mode
            obj.writeRegH(obj.MODE_CTRL, 1);
            obj.Sampling = 1;
        end

        function gotoConfig(obj)
        % Go to CONFIG mode
            obj.writeRegH(obj.MODE_CTRL, 2);
            obj.Sampling = 0;
        end
    end

    methods(Access = 'protected')
    % These methods are protected, (i.e. only accessible from methods of
    % this class or subclasses).

        function assignGpios(obj)
        % Assign RESET & DRDY pin for GPIO function
            % Define RESET as output & Set HIGH
            configurePin(obj.rpi, obj.RpiPinReset, 'DigitalOutput');
            writeDigitalPin(obj.rpi, obj.RpiPinReset, 1);
            fprintf('\nRESET# pin: %d', obj.RpiPinReset);

            % Define DRDY as input
            configurePin(obj.rpi, obj.RpiPinDrdy, 'DigitalInput');
            fprintf('\nDRDY pin: %d', obj.RpiPinDrdy);
        end

        function powerOn(obj)
        % Power On sequence returns 1 if no errors
            % Check for NOT_READY bit
            fprintf('Check NOT_READY\n');
            tmprd = 4;
            while (tmprd == 4)
                tmp = obj.readReg(obj.GLOB_CMD);
                tmprd = bitand(tmp(1), 4);
                pause(obj.NOTREADY_DELAY);
            end
            tmp = obj.readReg(obj.GLOB_CMD);
            if bitand(tmp(2), hex2dec('E0')) == 0
                fprintf('No Errors Detected\n');
            else
                error('HARD_ERR\n');
            end
        end

        function retval = isSampling(obj)
        % Read MODE_STAT bit to determine if in SAMPLING or not
        % returns 1 if currently in SAMPLING mode
            retval = 0;
            tmp = obj.readReg(obj.MODE_CTRL);
            if tmp(1) == 0
                retval = 1;
            end
        end

        function burstData = getSamples(obj, nsamples)
        % If not already, go to SAMPLING mode, check DRDY, send BURST_CMD
        % and get burst samples
            if(nargin > 0)
                n = nsamples;
            else
                n = 1;
            end
            if obj.Sampling == 0
                obj.gotoSampling();
            end

            % dummy data to send
            dummy = zeros(1, obj.BytesPerBurst);

            % store
            burstData = zeros(n, obj.BytesPerBurst);

            fprintf('Reading %d samples...\n', n);
            for i = 1: n
                pinvalue = 0;
                while (pinvalue == 0)
                    pinvalue = readDigitalPin(obj.rpi, obj.RpiPinDrdy);
                end
                % Send BURST_CMD
                obj.Sensor.writeRead([128 0]);
                % tSTALL1
                pause(obj.TSTALL1);
                % Burst Read
                burstData(i, :) = obj.Sensor.writeRead(dummy);
            end
        end
    end
end