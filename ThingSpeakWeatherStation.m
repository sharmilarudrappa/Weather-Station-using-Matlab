%%% ThingSpeak Weather Station Data Analysis

%%Retrieve data from ThingSpeak channel
% Channel ID to read data from
readChannelID = 87179;
% Specify date range
dateRange = [datetime('March 7, 2016'),datetime('March 13, 2016')];
% Read data including the timestamp, and channel information.
[data,time,channelInfo] = thingSpeakRead(readChannelID,'Fields',1:7,'DateRange',dateRange);
% Create variables to store different sorts of data
temperatureData = data(:,1);
humidityData = data(:,2);
pressureData = data(:,3);
rainData = data(:,4);
windSpeedData = data(:,5);
windGustData = data(:,6);
windDirectionData = data(:,7);


%%Temperature, Humidity, Pressure, Rain, WindSpeed, WindDirection histogram
% Create subplots
figure % creates a figure window
% Temperature histogram
subplot(2,3,1) % Create 2-by-3 axis on the same figure, and work on the first axis
histogram(temperatureData);
title(channelInfo.FieldDescriptions{1});
grid on

% Humidity histogram
subplot(2,3,2)
histogram(humidityData);
title(channelInfo.FieldDescriptions{2});
grid on

% Pressure histogram
subplot(2,3,3)
histogram(pressureData);
title(channelInfo.FieldDescriptions{3});
grid on

% Rain fall histogram
subplot(2,3,4)
histogram(rainData);
title(channelInfo.FieldDescriptions{4});
grid on

% WindSpeed histogram
subplot(2,3,5)
histogram(windSpeedData);
title(channelInfo.FieldDescriptions{5});
grid on

% Wind Direction histogram
rad = windDirectionData*pi/180; % Convert to radians
rad = -rad+pi/2; % Adjust the wind direction data to match map compass, such that North is equal to 0 degree
subplot(2,3,6)
polarhistogram(rad,12) % Plot the wind direction histogram in a polar axis
title(channelInfo.FieldDescriptions{7})
ax = gca;
ax.View = [0 90]; % Rotate axis 90 degrees counterclock-wise such that North is equal to 0 degree

%%Interpolation and contour for Temperature, Humidity and Pressure
% Replace missing data by interpolation, rather than removing the missing data directly 
% from the variable. This allows to keep the dimension of the array being consistent
xNew = linspace(1,size(data,1),100)'; % Create new x coordinates
tNew = interp1(temperatureData(~isnan(temperatureData)),xNew,'linear','extrap'); 
% Temperature interpolation. Extrapolation is applied here in case that the last entry is NaN.
hNew = interp1(humidityData(~isnan(humidityData)),xNew,'linear','extrap'); % Humidity interpolation
pNew = interp1(pressureData(~isnan(pressureData)),xNew,'linear','extrap'); % Pressure interpolation

% Find the index of the max pressure
[pMax,idx] = max(pNew);

% Create surface fitting data
sf = fit([tNew,hNew],pNew,'linearinterp');

% Plot
figure
hsf = plot(sf,[tNew,hNew],pNew); 
% Plot the surface with nodes. This plot function is provided in Curve Fitting Toolbox. 
%The output is an array of a surface object and a line object.
hsf(1).EdgeColor = 'interp'; % Change face edge color of the surface
hsf(1).FaceAlpha = 0.5; % Change the transparency of the surface
xlabel('Temperature')
ylabel('Humidity')
zlabel('Pressure')
title('Linear Interpolation Surface')

% 2D View with the location of max pressure
figure
hsf = plot(sf); % Plot the surface only
hsf.EdgeColor = 'interp'; % Change face edge color
hold on
plot3(tNew(idx),hNew(idx),pMax,'r.', 'MarkerSize',30) 
% Plot the location of max pressure
text(tNew(idx)+2,hNew(idx)+2,pMax,['P= ',num2str(pMax),', T=',...
    num2str(tNew(idx)),', H=',num2str(hNew(idx))]) 
% Display the values at the location above
title('Contour of the Pressure')
xlabel('Temperature')
ylabel('Humidity')
grid off
view(2) % Set the view to 2D, i.e., observing the plot from top to bottom along z-axis
hold off

%%Wind Compass and Feather
% Specify the latest n+1 wind directions to be displayed
n = 9;

% Convert to radians
rad = windDirectionData*pi/180;

% Create a feather plot
% Remove missing data and any wind speed with value 0
idx = (~isnan(rad)) & (~isnan(windSpeedData)) & (windSpeedData~=0);
% Convert polar coordinates to Cartesian. Note that dividing by the maximum
% wind speed allows to scale the length of each arrow by its relative wind
% speed, rather than the wind direction.
[x,y] = pol2cart(rad(idx),windSpeedData(idx)/max(windSpeedData(idx)));
% Plot
figure
subplot(2,1,2)
feather(x((end-n):end),y((end-n):end)) % Plot the feather
xlim([0 n+2]) % Adjust the x-axis
ylim([-1 1]) % Adjust the y-axis
xlabel(['The last ',num2str(n+1),' wind direction']) % Add x lable
title('Wind Direction Changes')
grid on
ax = gca;
ax.YTickLabel = {}; % Hide the Y-Tick
ax.XTick = 1:(n+1); % Adjust the X-Tick for n+1 data

% Create a compass plot
% Adjust the wind direction to match map compass, such that North is equal to 0 degree
rad = -rad+pi/2;
% Calculate the cosine component
u = cos(rad) .* windSpeedData; % x coordinate of wind speed on circular plot
% Calculate the sine component
v = sin(rad) .* windSpeedData; % y coordinate of wind speed on circular plot
% Plot
subplot(2,1,1)
compass(u((end-n):end),v((end-n):end)) % Plot compass
title('Wind Compass')
ax = gca;
ax.View = [-90 90]; % Rotate axis 90 degrees counterclock-wise such that North is equal to 0 degree
