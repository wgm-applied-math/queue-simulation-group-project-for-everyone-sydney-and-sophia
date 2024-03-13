%%
% 
%   for x = 1:10
%       disp(x)
%   end
% 
% Script that runs a ServiceQueue simulation many times and plots a
% histogram

%% Set up

% Set up to run 100 samples of the queue.
n_samples = 100;

% Each sample is run up to a maximum time of 1000.
max_time = 1000;

% Record how many customers are in the system at the end of each sample.
NInSystemSamples = cell([1, n_samples]);

%Record time customers spend in the system
TimeInSystemSamples = cell([1, n_samples]);

%Record time customers spend in the system
TimeInSystemSamples = cell([1, n_samples]);
TimeWaitingSamples = cell([1, n_samples]);
TimeBeingServedSamples = cell([1, n_samples]);

%% Run the queue simulation

% The statistics seem to come out a little weird if the log interval is too
% short, apparently because the log entries are not independent enough.  So
% the log interval should be long enough for several arrival and departure
% events happen.
for sample_num = 1:n_samples
    q = ServiceQueue(DepartureRate = (1/1.5), DepartureRateHelper = (1/1.5), LogInterval=100);
    q.schedule_event(Arrival(1, Customer(1)));
    run_until(q, max_time);
    % Pull out samples of the number of customers in the queue system. Each
    % sample run of the queue results in a column of samples of customer
    % counts, because tables like q.Log allow easy extraction of whole
    % columns like this.
    NInSystemSamples{sample_num} = q.Log.NWaiting + q.Log.NInService;
    TimeInSystemSamples{sample_num} = ...
        cellfun( ... 
            @(c) c.DepartureTime - c.ArrivalTime, ... 
            q.Served');
    TimeWaitingSamples{sample_num} = ...
        cellfun( ... 
            @(c) c.DepartureTime - c.ArrivalTime, ... 
            q.Served');
    TimeBeingServedSamples{sample_num} = ...
        cellfun( ... 
            @(c) c.DepartureTime - c.ArrivalTime, ... 
            q.Served');
end

% Join all the samples. "vertcat" is short for "vertical concatenate",
% meaning it joins a bunch of arrays vertically, which in this case results
% in one tall column.
NInSystem = vertcat(NInSystemSamples{:});
TimeInSystem = vertcat(TimeInSystemSamples{:});
TimeWaiting = vertcat(TimeWaitingSamples{:});
TimeBeingServed = vertcat(TimeBeingServedSamples{:});

% MATLAB-ism: When you pull multiple items from a cell array, the result is
% a "comma-separated list" rather than some kind of array.  Thus, the above
% means
%
%    NInSystem = horzcat(NInSystemSamples{1}, NInSystemSamples{2}, ...)
%
% which horizontally concatenates all the lists of numbers in
% NInSystemSamples.
%
% This is roughly equivalent to "splatting" in Python, which looks like
% f(*args).

%% Make a picture

% Start with a histogram.  The result is an empirical PDF, that is, the
% area of the bar at horizontal index n is proportional to the fraction of
% samples for which there were n customers in the system.
h = histogram(NInSystem, Normalization="probability", BinMethod="integers");

% MATLAB-ism: Once you've created a picture, you can use "hold on" to cause
% further plotting function to work with the same picture rather than
% create a new one.
hold on;

% For comparison, plot the theoretical results for a M/M/1 queue.
% The agreement isn't all that good unless you run for a long time, say
% max_time = 10,000 units, and LogInterval is large, say 10.
rho1 = q.ArrivalRate / q.DepartureRate;
rho2 = q.ArrivalRate / q.DepartureRateHelper;

P0 = 1 - rho1;
P02 = 1 / (1 + (rho1) * (1 / (1 - (rho2))));
nMax = 10;
ns = 0:nMax;
wn = 0:nMax;
P = zeros([1, nMax+1]);
P2 = zeros([1, nMax+1]);
P(1) = P0;
P2(1) = P02;


for n = 1:nMax
        P(1+n) = P0 * rho1^n;
end

%plot red dots for WITHOUT ASSISTANT
plot(ns, P, 'o', MarkerEdgeColor='k', MarkerFaceColor='r');

for n = 1:nMax
 P2(1+n) = P0 * rho1 * rho2^(n-1);
end 

%plot blue dots for WITH ASSISTANT
plot(wn, P2, 'o', MarkerEdgeColor='k', MarkerFaceColor='b');

%% Histogram of the time spent in the system
fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);
hold(ax, "on");
h = histogram(ax, TimeInSystem, Normalization = "probability"); 
title(ax, "Time in system");
xlabel(ax, "Time (minutes)");
ylabel(ax, "Probability");
exportgraphics(fig, ... 
    sprintf("Time in system histogram with DepartureRateHelper=%s.pdf", ...
    string(q.DepartureRateHelper)));

%% Histogram of the time customers spend waiting in queue
fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);
hold(ax, "on");
h = histogram(ax, TimeWaiting, Normalization = "probability"); 
title(ax, "Time waiting");
xlabel(ax, "Time (minutes)");
ylabel(ax, "Probability");
exportgraphics(fig, ... 
    sprintf("Time waiting histogram with DepartureRateHelper=%s.pdf", ...
    string(q.DepartureRateHelper)));

%% Histogram of the time customers spend being served
fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);
hold(ax, "on");
h = histogram(ax, TimeBeingServed, Normalization = "probability"); 
title(ax, "Time being served");
xlabel(ax, "Time (minutes)");
ylabel(ax, "Probability");
exportgraphics(fig, ... 
    sprintf("Time being served histogram with DepartureRateHelper=%s.pdf", ...
    string(q.DepartureRateHelper)));



% This sets some paper-related properties of the figure so that you can
% save it as a PDF and it doesn't fill a whole page.
% gcf is "get current figure handle"
% See https://stackoverflow.com/a/18868933/2407278
fig = gcf;
fig.Units = 'inches';
screenposition = fig.Position;
fig.PaperPosition = [0 0 screenposition(3:4)];
fig.PaperSize = [screenposition(3:4)];