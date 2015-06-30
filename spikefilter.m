function [xfilt,spike] = spikefilter(x,fs,spike)


% Simple script to remove outliers through iterative thresholding. Outliers
% are removed by first applying a z-score transform and rejecting all
% outliers that exceed a given threshold magnitude (defualt is 10), then 
% repeating the first step with remaining data points until no outliers 
% remain beyond the threshold. Data are windowed by a function that convolves
% a tapered log(1 - Hann + eps) window with the  
%
% Use: [xfilt,out] = spikefilter(x,fs,[options])
%
% Inputs:
%
%   x - A column vector with data
%   fs - sampling frequency
%   options  - A structure with the following fields: 
%          .threshold  -       
%
%

% ----------- SVN REVISION INFO ------------------
% $URL$
% $Revision$
% $Date$
% $Author$
% ------------------------------------------------

if nargin < 3
    spike.threshold = 10; % This is the threshold used in detecting spikes. 
                          % Z-score is computed iteratively until
                          % no points exceed this value. The threshold is set
                          % high by default because the main purpose here is to avoid
                          % distortion of kurtosis used in the
                          % kurtosis-threshold.
    spike.smoothwindow = .2;% Apply hanning window of given duration to smooth the spike filter.
    
    spike.interpolate = false; % If true, interpolates values through a weighted average, 
                               % with a Hann interpolation window twice
                               % the size of the smoothing window.
                               % If false, then data are subjected to
                               % simple windowing, with excluded points
                               % scaled towards zero.
                               % If a scalar value is given, then uses a
                               % Hann window of the given duration. 
                               % A vector is taken directly as the interpolation window.
end

spks = false(size(x));
newspks = true;
while any(newspks)
       z = (x-mean(x(~spks)))/std(x(~spks));
       newspks = abs(z)>spike.threshold &~spks; 
       spks = newspks | spks;
end
if isscalar(spike.smoothwindow)
    win = hanning(ceil(spike.smoothwindow.*fs));
else
    win = spike.smoothwindow; 
end

if isscalar(spike.interpolate) && spike.interpolate
    if islogical(spike.interpolate)
          %%% Use a default interpolation window with twice the support of the smoothing
          %%% window.
        interpwin = hanning(round(length(win)*2));
    else
        %%% Scalar values are treated as the interpolation window duration
        interpwin = hanning(ceil(spike.interpolate.*fs));
    end
elseif ~isscalar(spike.interpolate)
    %%% For a non-scalar value, the input is the window. 
    interpwin = spike.interpolate;
else
    interpwin = 0;
end
   
        
    
spike.filter = exp(convn(log(1-spks+eps),win,'same'));
spike.filter(spike.filter<0)=0;

%interpwin = win;
if ~isequal(interpwin,0)
    %%% Smooth x through weighted averaging. 
    xconv = convn(x.*spike.filter,interpwin,'same')./convn(spike.filter,interpwin,'same');
    xinterp = + (1-spike.filter).*xconv;
else
    xinterp = 0;
end

xfilt = x.*spike.filter + xinterp;

