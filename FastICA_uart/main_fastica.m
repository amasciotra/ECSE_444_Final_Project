clear;
clc;

instrreset

%get arduino serial port and initialize the serial connection
seriallist
f=serial(seriallist, 'BaudRate', 115200, 'InputBufferSize', 16000);

fopen(f);
temp = zeros(1,16000); %mixed signal 1 
temp2 = zeros(1,16000); %mixed signal 2


%Receive the samples from keil and store them in their respective array 
count = 0;
while(count < 16000) 
    count = count +1;
    temp(count) = fread(f, 1, 'uint8');
    temp2(count) = fread(f, 1, 'uint8');
end
fclose(f);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% scale the 8 bits sample to a range of [-1, 1] 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
temp = temp.*2; 
temp = temp./255;  
temp = temp -1;

temp2 = temp2.*2; 
temp2 = temp2./255; 
temp2 = temp2 -1; 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mixing the sine waves
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 s = [temp;temp2];
% % 
%  randn('seed', 1);
%  A = randn(2,2);
%  x = A*s;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Performing FastICA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[u, A_est, W] = fastica(s);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plotting and display the mixed signal and the unmixed signal 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(3,2,1);
axis([-2 2 0 600])
plot(s(1,1:600));
title('s1(t)');

subplot(3,2,2);
axis([-2 2 0 600])
plot(s(2,1:600));
title('s2(t)');

subplot(3,2,3);
axis([-2 2 0 600])
plot(u(1,1:600));
title('u1(t)');

subplot(3,2,4);
axis([-2 2 0 600])
plot(u(2,1:600));
title('u2(t)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% scale the signal to 8 bits and send to UART 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%scale it to 255 for DAC 
min1 = min(u(1,:)); 
max1 = max(u(1,:));
min2 = min(u(2,:)); 
max2 = max(u(2,:)); 

%signal 1 
u(1,:) = u(1,:) + (-1*min1); 
u(1,:) = u(1,:).*255; 
u(1,:) = u(1,:)./(max1+(-1*min1)); 

%signal 2
u(2,:) = u(2,:) + (-1*min2); 
u(2,:) = u(2,:).*255; 
u(2,:) = u(2,:)./(max2+(-1*min2)); 

%send back the unmixed sine wave to keil
count = 0;
s=serial(seriallist, 'BaudRate', 115200, 'InputBufferSize', 16000);
fopen(f);

while(count < 16000) 
    count = count +1;
    fwrite(f, u(1,count), 'uint8');
    fwrite(f, u(2,count), 'uint8');
end

fclose(f);
