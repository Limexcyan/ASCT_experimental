function wyn = m_randint(rows,cols,range)
% in older versions of Matlab function randi is not available

state = [];
      m		= rows;
      n  	= cols;

if isempty(m)
   m = 1;
end
if isempty(n)
   n = m;
end
if isempty(range)
   range = [0, 1];
end

len_range = size(range,1) * size(range,2);

% Typical error-checking.
if (~isfinite(m)) | (~isfinite(n))
   error('Matrix dimensions must be finite.');
elseif (floor(m) ~= m) | (floor(n) ~= n) | (~isreal(m)) | (~isreal(n))
   error('Matrix dimensions must be real integers.');
elseif (m < 0) | (n < 0)
   error('Matrix dimensions must be positive.');
elseif (length(m) > 1) | (length(n) > 1)
   error('Matrix dimensions must be scalars.');
elseif len_range > 2
   error('The IRANGE parameter should contain no more than two elements.');
elseif max(max(floor(range) ~= range)) | (~isreal(range)) | (~isfinite(range))
   error('The IRANGE parameter must only contain real finite integers.');
end

% If the IRANGE is specified as a scalar.
if len_range < 2
    if range < 0
       range = [range+1, 0];
    elseif range > 0
       range = [0, range-1];
    else
       range = [0, 0];    % Special case of zero range.
    end
end

% Make sure IRANGE is ordered properly.
range = sort(range);

% Calculate the range the distance for the random number generator.
distance = range(2) - range(1);

% Set the initial state if specified.
if ~isempty(state)
   rand('state', state);
end

% Generate the random numbers.
r = floor(rand(m, n) * (distance+1));

% Offset the numbers to the specified value.
wyn = ones(m,n)*range(1);
wyn = wyn + r;

% [EOF] randint.m
