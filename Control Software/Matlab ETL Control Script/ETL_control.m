%% ETL Driver Control (working on 2022B)
global CH DH
ETL = openNi845x(); %Call custom function to create an I2C Structure
DH = ETL.DeviceHandle;
CH = ETL.ConfigHandle;
%% I2C Configuration
calllib('ni845x_lib','ni845xI2cWrite',ETL.DeviceHandle,ETL.ConfigHandle,uint32(2),[uint8(0x03), uint8(3)]); %Get out of sleep mode
calllib('ni845x_lib','ni845xI2cWrite',ETL.DeviceHandle,ETL.ConfigHandle,uint32(2),[uint8(0x09), uint8(2)]); %Update Output Mode
calllib('ni845x_lib','ni845xI2cWrite',ETL.DeviceHandle,ETL.ConfigHandle,uint32(2),[uint8(0x0A), uint8(2)]); %Update Max Current Limits

%% User Interface and Callbacks
GUI; %initialize the GUI
%% Loading the API and I2C Config
function ni845x = openNi845x()
error = ones(10,1); %Check the errors as functions are called
ni845x.ClockRate  = 100; %100kHz Clock Rate
%Load in the NI845x C API
    if not(libisloaded('ni845x_lib'))
        loadlibrary('C:\Windows\System32\ni845x.dll','C:\Program Files (x86)\National Instruments\NI-845x\MS Visual C\ni845x.h','alias','ni845x_lib')
    end
%Find the NI device and get the DeviceHandle
[error(1), ni845x.FindDeviceHandle, ni845x.FirstDevice, ni845x.NumberFound] = calllib('ni845x_lib','ni845xFindDevice',blanks(260), 100, 100);
[error(2), ni845x.DeviceName, ni845x.DeviceHandle] = calllib('ni845x_lib','ni845xOpen', ni845x.FindDeviceHandle, 100);
%Set the Digital I/O voltage level
error(3) = calllib('ni845x_lib','ni845xSetIoVoltageLevel', ni845x.DeviceHandle, 33); %set Digital I/O to 1.5V
error(4) = calllib('ni845x_lib','ni845xI2cSetPullupEnable', ni845x.DeviceHandle,0); %disable the onboard pullup resistors

%Open the I2C config
[error(5), ni845x.ConfigHandle] = calllib('ni845x_lib','ni845xI2cConfigurationOpen',100); %Open i2c config
error(6) = calllib('ni845x_lib','ni845xI2cConfigurationSetClockRate',ni845x.ConfigHandle,uint16(100)); %Clock rate to 100kHz
error(7) = calllib('ni845x_lib','ni845xI2cConfigurationSetAddressSize',ni845x.ConfigHandle,int32(0)); %Slave address size to 7-bit
error(8) = calllib('ni845x_lib','ni845xI2cConfigurationSetAddress',ni845x.ConfigHandle,uint16(0x77)); %Slave address without R/W pin
[error(9), ni845x.SlaveAddress] = calllib('ni845x_lib','ni845xI2cConfigurationGetAddress',ni845x.ConfigHandle,100); %Get slave address
[error(10), ni845x.AddressSize] = calllib('ni845x_lib','ni845xI2cConfigurationGetAddressSize',ni845x.ConfigHandle,100); %Get slave address size

%Error reporting
    if max(error)>0
        disp('Error Somewhere, Need to Figure That Out Breh');
    else
        disp('No Errors, I2C Configured Successfully')
    end
%%
end
%% GUI
function GUI
% Create figure window

fig = uifigure('Position',[445 145 600 235]);
fig.Color = [1 1 1];

ETL_Slider_Display = uieditfield(fig,'numeric',...
    'Position',[275 120 60 20],...
    'Value', 0);

uilabel(fig,'Text','10-Bit Value','Position',[345 120 190 20],...
    'FontName', 'Helvetica',...
    'FontWeight', 'bold');

uilabel(fig,'Text','Electro-Tunable Lens Control','Position',[15 120 250 36],...
    'VerticalAlignment', 'center',...
    'HorizontalAlignment', 'center',...
    'FontName', 'Helvetica',...
    'FontWeight', 'bold',...
    'FontSize', 16,...
    'BackgroundColor', [0.9 0.9 0.9]);

uilabel(fig,'Text','2-Photon Mini-Scope ETL Control Golshani Lab UCLA','Position',[0 180 600 30],...
    'VerticalAlignment', 'center',...
    'HorizontalAlignment', 'center',...
    'FontName', 'Helvetica',...
    'FontWeight', 'bold',...
    'FontSize', 16,...
    'BackgroundColor', [0.8 0.8 0.8]);

% ETL Depth Slider
ETL_Control_Slider = uislider(fig,...
    'Position',[50 95 335 3],...
    'FontSize', 12,...
    'FontName', 'Helvetica',...
    'FontWeight', 'bold',...
    'Limits',[0 1000],...
    'Value',500,...
    'MajorTicks',[0,250,500,750,1000],...
    'MajorTickLabels',{'-100%','-50%','0','50%','100%'},...
    'ValueChangingFcn',@(ETL_Control_Slider,event) ETL_Slider_Changed(ETL_Control_Slider,event,ETL_Slider_Display));

% Control Buttons for things     

ETL_Sleep_Button = uibutton(fig,'state',...
               'FontSize', 12,...
               'FontName', 'Helvetica',...
               'FontWeight', 'bold',...
               'Position',[450, 60, 100, 30],...
               'Text','ETL Active',...
               'Value', true,...
               'BackgroundColor', [1 0 0],...
               'ValueChangedFcn', @(ETL_Sleep_Button,event) ETL_Sleep(ETL_Sleep_Button,event));

end
%%
function ETL_Slider_Changed(ETL_Control_Slider,event,ETL_Slider_Display)
global DH CH 

ETL_Slider_Display.Value = round(event.Value);
ETL_value = dec2bin(round(event.Value),10); %Convert current decimal value to binary
ETL_MSB = bin2dec(ETL_value(1:8)); %Extract the most significant 8 bits and convert to decimal
ETL_LSB = bin2dec([ETL_value(9:10),ETL_value(9:10),ETL_value(9:10),ETL_value(9:10)]); %Extract the least significant 2 bits
%Update the shift registers in the ETL Driver to update the lens
%disp(ETL_value);
assignin('base', 'ETL_Set_Value', ETL_value);
calllib('ni845x_lib','ni845xI2cWrite',DH,CH,uint32(2),[uint8(0x04), ETL_LSB ]); %LSBs LLV1-LLV4
calllib('ni845x_lib','ni845xI2cWrite',DH,CH,uint32(2),[uint8(0x05), ETL_MSB]); %MSBs LLV1
calllib('ni845x_lib','ni845xI2cWrite',DH,CH,uint32(2),[uint8(0x06), ETL_MSB]); %MSBs LLV2
calllib('ni845x_lib','ni845xI2cWrite',DH,CH,uint32(2),[uint8(0x07), ETL_MSB]); %MSBs LLV3
calllib('ni845x_lib','ni845xI2cWrite',DH,CH,uint32(2),[uint8(0x08), ETL_MSB]); %MSBs LLV4
%calllib('ni845x_lib','ni845xI2cWrite',DH,CH,uint32(2),[uint8(0x03), uint8(3)]); %Get out of sleep mode
calllib('ni845x_lib','ni845xI2cWrite',DH,CH,uint32(2),[uint8(0x09), uint8(2)]); %Update Output Mode

persistent Counter
if isempty(Counter)
  Counter = 0;
end
Counter = Counter + 1;

 if rem(Counter,20) == 0 || Counter == 0
    disp(['ETL Value Set to ',num2str(ETL_Slider_Display.Value),' in 10 Bit Resolution']);
 end

 end

function ETL_Sleep(ETL_Sleep_Button,event)
global DH CH
val = event.Value;
if val == 1
    calllib('ni845x_lib','ni845xI2cWrite',DH,CH,uint32(2),[uint8(0x03), uint8(3)]); %Wake
    ETL_Sleep_Button.BackgroundColor = [1 0 0];
    disp('ETL Enabled');
else
    calllib('ni845x_lib','ni845xI2cWrite',DH,CH,uint32(2),[uint8(0x03), uint8(0)]); %Sleep
    ETL_Sleep_Button.BackgroundColor = [1 1 1];
    disp('ETL Disabled');
end
    
end

