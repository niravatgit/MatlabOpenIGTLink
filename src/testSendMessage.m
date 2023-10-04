%disable CRC check on slicer with 
%slicer.mrmlScene.GetNodeByID('vtkMRMLIGTLConnectorNode1').SetCheckCRC(0)
igtlConnection = igtlConnect('127.0.0.1',18944);
sender = OpenIGTLinkMessageSender(igtlConnection);

for t=1:1
    num_points = 30;
    tData = zeros(4,4,num_points);
    fiducialListName = 'NeedleShape';
    for i=1:1000
        tic
        needleTraj = rand(3,num_points)*5;
        needleTraj(3,:) = 1:5:num_points*5;
        tData(1:3,4,:) = needleTraj;
        sender.igtlSendTDATAMessage(fiducialListName, tData);
        toc
    end

%     fiducialListName = 'NeedleShape';
%     for i=1:1000
%         tic
%         needleTraj = rand(30,3)*5;
%         needleTraj(:,3) = 1:5:150;
%         sender.igtlSendPointMessage(fiducialListName, needleTraj);
%         toc
%     end
%   msg = 'Hello';
%   sender.igtlSendStringMessage('CMD_0001', msg);
%   
%   msg1 = [ '<Command Name=''SetVar'' insertion_depth=''' , num2str(t/2,5) , '''/>'];
%   sender.WriteOpenIGTLinkStringMessage('CMD_0001', msg1);
%   
%   data = [1.23456, 2, 3];
%   sender.Write1DFloatArrayMessage('CMD_001', data);
%   
%   matrix = [ 1.34567 0 0 t; 0 1 0 0; 0 0 1 0; 0 0 0 1 ];
%   sender.igtlSendTransformMessage('TARGET_001', matrix);
%   pause(1)

end

igtlDisconnect(igtlConnection);

