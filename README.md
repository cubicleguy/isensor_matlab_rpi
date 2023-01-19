# Disclaimer
--------------

THE SOFTWARE IS RELEASED INTO THE PUBLIC DOMAIN.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, NONINFRINGEMENT,
SECURITY, SATISFACTORY QUALITY, AND FITNESS FOR A PARTICULAR PURPOSE.
IN NO EVENT SHALL EPSON BE LIABLE FOR ANY LOSS, DAMAGE OR CLAIM, ARISING FROM OR
IN CONNECTION WITH THE SOFTWARE OR THE USE OF THE SOFTWARE.

# Purpose of this software
-----------------------
This is demonstration software for evaluation purpose to communicate using Matlab with a supported Epson sensor connected to a Raspberry Pi that is networked to a PC.
The user is expected to modify the scripts and extend the functionality to meet their specific evaluation requirements.


# Test machine
--------------

* WIN10 Pro 64-bit/PC Core i5-6500 @ 3.2GHz, 16GB RAM
* Matlab R2018a (9.4.0.813654) 64-bit
* Raspberry Pi B+
  * Raspberry Pi connected to Epson IMU with SPI Interface using
    Epson M-G32EV031 Breakout Board
  * Epson IMU M-G3xx & Epson Accel M-A352AD10
  * Direct Ethernet Connection between PC <--> RPi


# Requirements
--------------

* This requires a PC running MATLAB R2018a and MATLAB Support Package for Raspberry Pi Hardware
  v18.1.3 [web link](https://www.mathworks.com/help/supportpkg/raspberrypiio/index.html?searchHighlight=raspberry%20pi&s_tid=doc_srchtitle)

* This requires a PC connected by ethernet to the Raspberry Pi with Epson IMU attached to the
  SPI interface (UART interface is not supported).

* This assumes using customized version of Mathwork's Raspberry Pi OS
  installed on the Raspberry Pi Hardware and communicating with Matlab on
  the PC using an ethernet connection as part of the MATLAB Support Package for Raspberry Pi Hardware
  v18.1.3


# Important for RPi SPI Interface
-----------------------------

1. The MATLAB Support Package for Raspberry Pi should already
   enable the SPI interface on the Raspberry Pi.

2. This example is designed with the following pin-mapping:

Epson IMU     | Raspberry Pi
------------- | -------------
Epson_RESET#  | RPI_GPIO_P1_15 (GPIO22)
Epson_DRDY    | RPI_GPIO_P1_18 (GPIO24)
Epson_CS      | RPI_GPIO_P1_24 (GPIO08)/CE0
Epson_SCK     | RPI_GPIO_P1_23 (GPIO11)
Epson_MISO    | RPI_GPIO_P1_21 (GPIO9)
Epson_MOSI    | RPI_GPIO_P1_19 (GPIO10)


# How to use this software
-----------------------

1. Create a new object using the Epson Sensor model connected to the RPI SPI
   interface within Matlab.

   Specify the 3 interface parameters for SPI clock speed, Reset pin,
   DRDY pin as required for your hardware configuration.

   If the selected device model has a variant (i.e. G365PDF1 or G365PDC1, then a 4th parameter may be required to differentiate between model variants).

   Otherwise, passing no parameters keeps the assignments as default:
   speed=100000Hz, RpiPinReset=22, RpiPinDrdy=24

   For example, the default:

```
>> e = G365Imu(1000000, 22, 24);
RESET# pin: 22
DRDY pin: 24
Toggle RESET#
Check NOT_READY
No Errors Detected
Model: G365PDF1
Version: 40.20
Serial#: X0000013
```

   For example, in the case of SPI=500000, RpiPinReset=23, RpiPinDrdy=18;

```
>> e = G365Imu(500000, 23, 18);
RESET# pin: 23
DRDY pin: 18
Toggle RESET#
Check NOT_READY
No Errors Detected
Model: G365PDF1
Version: 40.20
Serial#: W0000501
>>

```

   The above will create handle object "e" representing the Epson Sensor
   connected to the RPI SPI interface. A hardware reset is always asserted
   to place the Epson IMU in a known state.
   Then the model number, version code, and serial number is read from the device.

2. Configure the device's burst output fields by writing a 1
   to desired object properties to enable the specific burst fields.

   #### For IMU Devices
   NOTE: Some IMU fields support 32-bit output which can be set by writing a 2

   Object Property | Description
   ----------------|------------
   Ndflag          | Enable NDFLAG field in burst sample, 16-bit only
   TempC           | Enable TEMPC field in burst sample 1=16-bit 2=32-bit
   Gyro            | Enable or disable Gyro X,Y,Z 1=16bit 2=32-bit
   Accl            | Enable or disable Accl X,Y,Z 1=16bit 2=32-bit
   DeltaA          | Enable or disable Delta Angle X,Y,Z 1=16bit 2=32-bit
   DeltaV          | Enable or disable Delta Velocity X,Y,Z 1=16bit 2=32-bit
   Quaternion      | *(Only for G365)* Enable or disable Quaternion q0,q1,q2, q3  1=16bit 2=32-bit
   Atti            | *(Only for G365)* Enable or disable Attitude ANG1, ANG2, ANG3 1=16bit 2=32-bit
   Gpio            | Enable GPIO field in burst sample 16-bit only
   Counter         | Enable 16-bit COUNT field in burst sample
   Chksm16         | Enable 16-bit CHKSM field in burst sample

   #### For Accelerometer Devices:

   Object Property | Description
   ----------------|------------
   Ndflag          | Enable 16-bit NDFLAG field in burst sample
   TempC           | Enable 32-bit TEMPC field in burst sample
   Counter         | Enable 16-bit COUNT field in burst sample
   Chksm16         | Enable 16-bit CHKSM field in burst sample
   TiltX           | Enable tilt output on X axis instead of accelerometer by setting to 1
   TiltY           | Enable tilt output on Y axis instead of accelerometer by setting to 1
   TiltZ           | Enable tilt output on Z axis instead of accelerometer by setting to 1

3. Select the desired output rate & filter setting by setting the object
   properties.

   #### For IMU Devices

   Object Property                                                        | Description
   -----------------------------------------------------------------------|------------
   DoutRate                                                               | 2000, 1000, 500, 250, 125, 62.5, 31.25, 15.625, 400, 200, 100, 80, 50, 40, 25, 20
   FilterSel (All IMUs, and G370PDF1 when DoutRate=2000, 400, or 80sps)   | tap0, tap2, tap4, tap8, tap16, tap32, tap64, tap128, 32fc50, 32fc100, 32fc200, 32fc400, 64fc50, 64fc100, 64fc200, 64fc400, 128fc50, 128fc100, 128fc200, 128fc400
   FilterSel (Only for G370PDF1 when DoutRate is not 2000, 400, or 80sps) | tap0, tap2, tap4, tap8, tap16, tap32, tap64, tap128, 32fc25, 32fc50, 32fc100, 32fc200, 64fc25, 64fc50, 64fc100, 64fc200, 128fc25, 128fc50, 128fc100, 128fc200

   NOTE: Refer to device datasheet for valid combinations of Output
         Rate vs Filter Selection
         i.e. For M-G3xx, Table 5.4 Supported Settings For Output Rate and Filter
              Cutoff Frequency

   #### For Accelerometer Devices

   Object Property      | Description
   ---------------------|------------
   DoutRate             | 1000, 500, 200, 100, 50
   FilterSel            | 64fc83, 64fc220, 128fc36, 128fc110, 128fc350, 512fc9, 512fc16, 512fc60, 512fc210, 512fc460

   NOTE: Refer to device datasheet for valid combinations of Output
         Rate vs Filter Selection
         i.e. For M-A352AD, Table 5.4 Supported Settings For Output Rate and Filter
              Cutoff Frequency

4. Optionally enable other operating modes

   #### For IMU Devices

   Object Property      | Description
   ---------------------|------------
   Gpio2Sel             | GPIO2 pin function can be gpio, counter_reset, or external_trigger


   #### For Accelerometer Devices

   Object Property     | Description
   --------------------|------------
   ReducedNoiseEn      | Reduce Noise Floor mode
   TempStabEn          | Bias stabilization against thermal shock
   ExtEnable           | External Trigger mode on falling edge

5. To initialize the Epson sensor with current object properties
   run the setDeviceCfg() method.

   *This method should be called after any changes to the object
   properties to propagate the changes to the sensor device.*

```
>> e.setDeviceCfg;
```

6. To retrieve scaled sensor data and store it in an array call the
   getScaledSamples(n) method while specifying the "n" as the number
   of sensor samples to read.

For example to store 500 samples to the scaleddata structure:

```
>>scaleddata = e.getScaledSamples(500);
```

   The above command will store the incoming scaled (converted) sensor data
   into an array while managing the SPI interface as follows:

   - If not already, place the device into SAMPLING mode
   - Checks for DRDY assertion
   - Send Burst Command
   - Burst Read Sensor Data (n samples)
   - Post processes the captured sensor data by applying the
     appropriate scale factors

   The default settings unless changed:

   #### For IMU Devices

   - Output date rate = 250Hz
   - Filter = Moving Average TAP=16
   - Burst Output = Ndflag, 16-bit TempC, 16-bit Gyro X,Y,Z, 16-bit Accl X,Y,Z, 16-bit Sample Counter, Chksm16

   #### For Accelerometer Devices

   - Output date rate = 200Hz
   - Filter Tap = 512 TAP Fcutoff = 60Hz
   - Burst Output = Ndflag, 32-bit TempC, 32-bit ACCL X,Y,Z, 16-bit Sample Counter, Chksm16

   ### Precautions For Processing Speed

   Due to processing latency of connection MATLAB --> RPi --> Epson Device
   & capability of the RaspberryPi hardware, IMU output rate may be limited.
   Data output rate above 200Hz may not be stable.

   If IMU sensor data can not be processed within data output rate timing,
   DRDY toggling will not be consistent and captured sensor data may
   have dropped sensor samples. Verify the processing speed/data rate by
   monitoring the DRDY toggle rate by an oscilloscope probe which should be
   equal to the specified DoutRate.

# EpsonDeviceRpi Object Description
---------------------------------

* Object properties must be propagated to the physical device register by calling
  the setDeviceCfg() method after properties are configured.
* To back propagate device register settings to the object properties call
  the getDeviceCfg() method


## Properties For IMU Devices
-------------

Property        | Description
----------------|------------
Accl            | Enable or disable Accl X,Y,Z 1=16bit 2=32-bit
Atti            | *(Only for G365, G330, G366)* Enable or disable Attitude ANG1, ANG2, ANG3 1=16bit 2=32-bit
BytesPerBurst   | Status indicating # of bytes per burst sample
Chksm16         | Enable 16-bit CHKSM field in burst sample
Counter         | Enable 16-bit COUNT field in burst sample
DeltaA          | Enable or disable Delta Angle X,Y,Z 1=16bit 2=32-bit
DeltaV          | Enable or disable Delta Velocity X,Y,Z 1=16bit 2=32-bit
DoutRate        | Output rate in Hz
ExtEnable       | Enable External Trigger
FieldsInBurst   | Status indicating fields in burst sample
FieldsPerBurst  | Status indicating # of fields per burst sample
FilterSel       | Filter selection
Gpio            | Enable GPIO field in burst sample
Gpio2Sel        | GPIO2 pin function can be gpio, counter_reset, or external_trigger
Gyro            | Enable or disable Gyro X,Y,Z 1=16bit 2=32-bit
Ndflag          | Enable NDFLAG field in burst sample
Quaternion      | *(Only for G365, G330, G366)* Enable or disable Quaternion q0,q1,q2,q3 1=16bit 2=32-bit
Sampling        | Status indicating SAMPLING mode
TempC           | Enable TEMPC field in burst sample 1=16-bit 2=32-bit
isPDC1          | *(Only for G365)* 0=G365PDF1 1=G365PDC1
isPDCA          | *(Only for G364)* 0=G364PDC0 1=G364PDCA
isPDS0          | *(Only for G370)* 0=G370PDF1 1=G370PDS0
is16G           | *(Only for G330, G366)* 0=8G 1=16G accelerometer output range
Sensor          | Sensor SPI object on Raspberry Pi
rpi             | Raspberry Pi object


## Properties For Accelerometer Devices
-------------

Property        | Description
----------------|------------
BytesPerBurst   | Status indicating # of bytes per burst sample
Chksm16         | Enable 16-bit CHKSM field in burst sample
Counter         | Enable 16-bit COUNT field in burst sample
DoutRate        | Output rate in Hz
ExtEnable       | Enable External Trigger
FieldsInBurst   | Status indicating fields in burst sample
FieldsPerBurst  | Status indicating # of fields per burst sample
FilterSel       | Filter selection
Ndflag          | Enable NDFLAG field in burst sample
ReducedNoiseEn  | Enable Reduce Noise Floor mode
Sampling        | Status indicating SAMPLING mode
TempC           | Enable TEMPC field in burst sample
TempStabEn      | Enable Bias Stabilization Against Temperature mode
TiltX           | Enable Tilt for X-axis in burst sample instead of acceleration
TiltY           | Enable Tilt for Y-axis in burst sample instead of acceleration
TiltZ           | Enable Tilt for Z-axis in burst sample instead of acceleration
Sensor          | Sensor SPI object on Raspberry Pi
rpi             | Raspberry Pi object


## Object Methods
----------

* Preferred method to configure the device is by setting the object properties and then calling the setDeviceCfg() method to write properties to the appropriate registers
* However, there are methods to access the device registers directly if needed
* Reading device register values directly by calling readReg() method
* To pass the register address to the readReg(<register address>), simply use the object_name.REG_NAME

For example to read MODE_CTRL register REG[0x02(W0)]:

```
>> e.readReg(e.MODE_CTRL, true);
REG[0x02 (W0)] > 0x0400
```

* Writing to device register values directly by calling the writeRegH() or
  writeRegL() methods to write to the HIGH byte or LOW byte respectively.
* NOTE: After writing directly to device registers, run getDeviceCfg() method to synchronize the object properties with current device register settings

For example to write a 0x01 to the HIGH byte of MODE_CTRL register REG[0x02(W0)]:

```
>> e.writeRegH(e.MODE_CTRL, 1, true);
REG[0x03 (W0)] < 0x01
```

For example to write a 0x06 to the LOW byte of MSC_CTRL register REG[0x02(W1)]:

```
>> e.writeRegL(e.MSC_CTRL, 6, true);
REG[0x02 (W1)] < 0x06
```

### Methods For IMU & Accelerometer Devices

Methods         | Description
----------------|------------
dumpReg         | Read back all register values
getDeviceCfg    | Update object properties by reading device registers
getModel        | Read back MODEL number
getScaledSamples| Call getSampling() and convert data to scaled values
getSerialId     | Read back SERIAL_NUM
getVersion      | Read back VERSION number
gotoConfig      | Go to CONFIG mode
gotoSampling    | Go to SAMPLING mode
printTabular    | Output a table listing with specified scaled sensor data
readReg         | Read a 16-bit value from specified WIN_ID & register address
resetDevice     | Assert hardware reset on RESET# pin and wait 800 msec
setDeviceCfg    | If not already goto CONFIG mode and program device registers
writeRegH       | Write to HIGH byte of specified WIN_ID & register address
writeRegL       | Write to LOW byte of specified WIN_ID & register address

### Additional Methods For IMU Devices

Methods         | Description
----------------|------------
testFlash       | Sets Flash test bit and waits for bit to clear to check result
testSelf        | Sets selftest bit and waits for bit to clear to check result


### Additional Methods For Accelerometer Devices

Methods         | Description
----------------|------------
doSelftests     | Perform device self tests (testSENS, testFlash, testACC, testTEMPC, testVDD)


# File Listing
--------------

File                   | Description
-----------------------|------------
EpsonDeviceRpi.m       | Handle object base class for Epson sensor device connected by SPI to RPI controlled by Matlab 
A352Accl.m             | Epson A352 Sensor object derived from base class EpsonDeviceRpi
G320Imu.m              | Epson G320 Sensor object derived from base class EpsonDeviceRpi
G354Imu.m              | Epson G354 Sensor object derived from base class EpsonDeviceRpi
G364Imu.m              | Epson G364PDCA/PDC0 Sensor object derived from base class EpsonDeviceRpi
G365Imu.m              | Epson G365PDF1/PDC1 Sensor object derived from base class EpsonDeviceRpi
G330_G366Imu.m         | Epson G330PDG0/G366PDG0 Sensor object derived from base class EpsonDeviceRpi
G370Imu.m              | Epson G370PDF1/PDS0 Sensor object derived from base class EpsonDeviceRpi
exampleEpsonAcclRpi.m  | Example matlab script creating Epson Accelerometer RPI object, configure, get sensor samples, print sensor data to console, plot
exampleEpsonImuRpi.m   | Example matlab script creating Epson IMU RPI object, configure, get sensor samples, print sensor data to console, plot
createAcclPlot.m       | Plot Accl X,Y,Z axes
createGyroPlot.m       | Plot Gyro X,Y,Z axes
README.md              | This readme file in markdown


# Change Record
--------------

Date       | Version | Description
-----------|---------|------------
2021-10-13 |  v1.0   |  Initial release
2023-01-10 |  v1.01  |  Minor maintenance, add G330/G366 support, fix deltaV scalefactor G365PDC1, formatting
