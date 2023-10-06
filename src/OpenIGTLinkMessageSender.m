function openIGTMessageSender = OpenIGTLinkMessageSender(igtlConnection)
    global socket;
    socket = igtlConnection.socket;    

    openIGTMessageSender.igtlSendStringMessage = @igtlSendStringMessage;
    openIGTMessageSender.igtlSend1DFloatArrayMessage = @igtlSend1DFloatArrayMessage;
    openIGTMessageSender.igtlSendTransformMessage = @igtlSendTransformMessage;
    openIGTMessageSender.igtlSendImageMessage = @igtlSendImageMessage;
    openIGTMessageSender.igtlSendPointMessage = @igtlSendPointMessage;
    openIGTMessageSender.igtlSendTDATAMessage = @igtlSendTDATAMessage;
end

function result=igtlSendStringMessage(deviceName, msgString)
    msg.dataTypeName='STRING';
    msg.deviceName=deviceName;
    msg.timestamp=igtlTimestampNow();
    msgString=[uint8(msgString) uint8(0)]; % Convert string to uint8 vector and add terminator character
    msg.body=[convertFromUint16ToUint8Vector(3),convertFromUint16ToUint8Vector(length(msgString)),msgString];
    result=WriteOpenIGTLinkMessage(msg);
end

function result=igtlSend1DFloatArrayMessage(deviceName, data)
    msg.dataTypeName='NDARRAY';
    msg.deviceName=deviceName;
    msg.timestamp=igtlTimestampNow();
    
    msg.body=[uint8(10), uint8(1), convertFromUint16ToUint8Vector(length(data))];
    for i=1:length(data)
        msg.body=[ msg.body, convertFromFloat32ToUint8Vector(data(i))];
    end
    result=WriteOpenIGTLinkMessage(msg);
end

function result=igtlSendPointMessage(deviceName, data)
    msg.dataTypeName='POINT';
    msg.deviceName=deviceName;
    msg.timestamp=igtlTimestampNow();
    
    if size(data,2)~=3
        disp('DATA MUST HAVE SIZE Nx3');
        result = -1;
        return;
    end

    %sizeOfPoint = 136;
    numPoints = size(data, 1);
    
    msg.body = [];
    
    group = 'Fiducal';
    color = [1,1,0,0];
    diamter = 1;
    owner = '';
    for i=1:numPoints
        name = ['F_' , num2str(i)];
        x = data(i,1);
        y = data(i,2);
        z = data(i,3);
        point_data = [];
        
        point_data=[point_data, padString(name,64)];
        point_data=[point_data, padString(group,32)];
        
        point_data=[point_data, uint8(color)];
        point_data=[point_data, convertFromFloat32ToUint8Vector(x)];
        point_data=[point_data, convertFromFloat32ToUint8Vector(y)];
        point_data=[point_data, convertFromFloat32ToUint8Vector(z)];
        point_data=[point_data, convertFromFloat32ToUint8Vector(diamter)];
        point_data=[point_data, padString(owner,20)];
        msg.body= [msg.body, point_data];
    end
    result=WriteOpenIGTLinkMessage(msg);  
end

function result=igtlSendTransformMessage(deviceName, transform)
    msg.dataTypeName='TRANSFORM';
    msg.deviceName=deviceName;
    msg.timestamp=igtlTimestampNow();
    % version number
    % note that it is an unsigned short value, but small positive signed and unsigned numbers are represented the same way, so we can use writeShort
    msg.body = [];
    msg.body=typecast(swapbytes(single(reshape(transform(1:3,:),1,[]))), 'uint8');

%     for i=1:4
%         for j=1:3
%             msg.body=[ msg.body, convertFromFloat32ToUint8Vector(transform(j,i))];
%         end
%     end
    result=WriteOpenIGTLinkMessage(msg);
end

function result=igtlSendTDATAMessage(deviceName, tData)
    msg.dataTypeName='TDATA';
    msg.deviceName=deviceName;
    msg.timestamp=igtlTimestampNow();
    
    if size(tData,1)~=4 && size(tData,2)~=4
        disp('DATA MUST HAVE SIZE 4x4xN');
        result = -1;
        return;
    end

    % version number
    % note that it is an unsigned short value, but small positive signed and unsigned numbers are represented the same way, so we can use writeShort
    msg.body = [];
    for i=1:size(tData, 3)
        t_data = [];
        t_data = [t_data, padString([deviceName , num2str(i)],20)];
        t_data = [t_data, uint8(2)];
        t_data = [t_data, uint8(0)];
        t_data = [t_data, typecast(swapbytes(single(reshape(tData(1:3,:,i),1,[]))), 'uint8')];
        msg.body = [msg.body, t_data];
    end
    result=WriteOpenIGTLinkMessage(msg);
end

function result=igtlSendImageMessage(deviceName, RI, RJ, RK , TX, TY, TZ, SX, SY, SZ, NX, NY, NZ, PX, PY, PZ, imageData)
tic
    msg.dataTypeName='IMAGE';
    msg.deviceName=deviceName;
    msg.timestamp=igtlTimestampNow();
    % version number
    % note that it is an unsigned short value, but small positive signed and unsigned numbers are represented the same way, so we can use writeShort
    msg.body = [convertFromUint16ToUint8Vector(1),... %Version
        uint8(1), ... %Number of Image Components (1:Scalar, >1:Vector). (NOTE: Vector data is stored fully interleaved.)
        uint8(4), ... %Scalar type (2:int8 3:uint8 4:int16 5:uint16 6:int32 7:uint32 10:float32 11:float64)
        uint8(2), ... %Endian for image data (1:BIG 2:LITTLE) (NOTE: values in image header is fixed to BIG endian)
        uint8(1), ... % image coordinate (1:RAS 2:LPS)
        convertFromUint16ToUint8Vector(RI), convertFromUint16ToUint8Vector(RJ), convertFromUint16ToUint8Vector(RK), ... %Number of pixels in each direction
        convertFromFloat32ToUint8Vector(TX),convertFromFloat32ToUint8Vector(TY), convertFromFloat32ToUint8Vector(TZ) ... %Transverse vector (direction for 'i' index) / The length represents pixel size in 'i' direction in millimeter
        convertFromFloat32ToUint8Vector(SX),convertFromFloat32ToUint8Vector(SY), convertFromFloat32ToUint8Vector(SZ) ... %Transverse vector (direction for 'j' index) / The length represents pixel size in 'j' direction in millimeter
        convertFromFloat32ToUint8Vector(NX),convertFromFloat32ToUint8Vector(NY), convertFromFloat32ToUint8Vector(NZ) ... %Normal vector of image plane(direction for 'k' index) / The length represents pixel size in 'z' direction or slice thickness in millimeter
        convertFromFloat32ToUint8Vector(PX),convertFromFloat32ToUint8Vector(PY), convertFromFloat32ToUint8Vector(PZ) ... %center position of the image (in millimeter) (*)
        convertFromUint16ToUint8Vector(0), convertFromUint16ToUint8Vector(0), convertFromUint16ToUint8Vector(0), ... %Number of pixels in each direction
        convertFromUint16ToUint8Vector(RI), convertFromUint16ToUint8Vector(RJ), convertFromUint16ToUint8Vector(RK) %Number of pixels in each direction
        ];
%     for i=1:size(imageData,1)
%         for j=1:size(imageData,2)
%             msg.body=[ msg.body, convertFromFloat32ToUint8Vector(imageData(i,j))];
%         end
%     end
%    
    %this next one statement does what above entire loop would do and above
    %loop used to take about 2 seconds while this statement takes 3
    %miliseconds
    msg.body=[ msg.body,  typecast((int16(reshape(imageData',1,[]))), 'uint8')];
%     disp(['Size of the Image Message Body=', num2str(length(uint8(msg.body)))]);
    result=WriteOpenIGTLinkMessage(msg);
toc
end

% Returns 1 if successful, 0 if failed
function result=WriteOpenIGTLinkMessage(msg)
    global socket;
    % Add constant fields values
    msg.versionNumber=1;
    msg.bodySize=length(msg.body);
    %disp(['Msg.BodySize=', num2str(msg.bodySize)]);

    msg.bodyCrc=0;%crc64(uint8(msg.body)); % TODO: compute this
    % Pack message
    data=[];
    data=[data, convertFromUint16ToUint8Vector(msg.versionNumber)];
    data=[data, padString(msg.dataTypeName,12)];
    data=[data, padString(msg.deviceName,20)];
    data=[data, convertFromInt64ToUint8Vector(msg.timestamp)];
    data=[data, convertFromInt64ToUint8Vector(msg.bodySize)];
    data=[data, convertFromInt64ToUint8Vector(msg.bodyCrc)];
    data=[data, uint8(msg.body)];    
    result=1;
    try
%         disp(['Length Of Data being writeen to socket=', num2str(length(data))]);
        %write data considering the output buffersize
        
        fwrite(socket, uint8(data));
    catch ME
        disp(ME.message)
        result=0;
    end
    if (result==0)
      disp('Sending OpenIGTLink message failed');
    end
end

function result=convertFromFloat32ToUint8Vector(float32Val)
    hex = num2hex(single(float32Val));
    
    result=zeros(1,4,'uint8');
    result(1)=uint8(hex2dec(hex(1:2)));
    result(2)=uint8(hex2dec(hex(3:4)));
    result(3)=uint8(hex2dec(hex(5:6)));
    result(4)=uint8(hex2dec(hex(7:8)));
end

function selectedByte=getNthByte(multibyte, n)
  selectedByte=uint8(mod(floor(multibyte/256^n),256));
end

function result=convertFromUint16ToUint8Vector(uint16Value)
    result = typecast(swapbytes(uint16(uint16Value)), 'uint8');
    %result=[getNthByte(uint16Value,1) getNthByte(uint16Value,0)];
end

function result=convertFromInt32ToUint8Vector(int32Value)
  result=zeros(1,4,'uint8');
  result(1)=getNthByte(int32Value,3);
  result(2)=getNthByte(int32Value,2);
  result(3)=getNthByte(int32Value,1);
  result(4)=getNthByte(int32Value,0);
end

function result=convertFromInt64ToUint8Vector(int64Value)
  result=zeros(1,8,'uint8');
  result(1)=getNthByte(int64Value,7);
  result(2)=getNthByte(int64Value,6);
  result(3)=getNthByte(int64Value,5);
  result(4)=getNthByte(int64Value,4);
  result(5)=getNthByte(int64Value,3);
  result(6)=getNthByte(int64Value,2);
  result(7)=getNthByte(int64Value,1);
  result(8)=getNthByte(int64Value,0);
end 

function paddedStr=padString(str,strLen)
  paddedStr=str(1:min(length(str),strLen));
  paddingLength=strLen-length(paddedStr);
  if (paddingLength>0)
      paddedStr=[paddedStr,zeros(1,paddingLength,'uint8')];
  end
end

function timestamp = igtlTimestampNow()
% igtlTimestampNow  Time elapsed since 00:00:00 January 1, 1970, UTC, in seconds
%
%   timestamp = igtlTimestampNow()
%
%  Example:
%
%   igtlConnection = igtlConnect('127.0.0.1',18944);
%   transform.name = 'NeedleToTracker';
%   transform.matrix = [ 1 0 0 10; 0 1 0 -5; 0 0 1 20; 0 0 0 1 ];
%   transform.timestamp = igtlTimestampNow();
%   igtlSendTransform(igtlConnection, transform);
%   igtlDisconnect(igtlConnection);
%

timestamp = java.lang.System.currentTimeMillis/1000;
end
function calcCRC64()
poly = [64,62,57,55,54,53,52,47,46,45,40,39,38,37,35,33,32,31,29,27,24,23,22,21,19,17,13,12,10,9,7,4,1,0];
H = comm.CRCGenerator('Polynomial', poly);

end
