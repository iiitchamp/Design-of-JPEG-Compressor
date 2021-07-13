JPEG compression algorithm implementation in MATLAB

*jpegCompress.m*
function y = jpegCompress(x, quality)
% y = jpegCompress(x, quality) compresses an image X based on 8 x 8 DCT
% transforms, coefficient quantization and Huffman symbol coding. Input 
% quality determines the amount of information that is lost and compression achieved. y is the encoding structure containing fields:
% y.size          size of x
% y.numblocks     number of 8 x 8 encoded blocks
% y.quality       quality factor as percent
% y.huffman       Huffman coding structure 

narginchk(1, 2);                   % check number of input arguments
if ~ismatrix(x) || ~isreal(x) || ~ isnumeric(x) || ~ isa(x, 'uint8')
    error('The input must be a uint8 image.');
end
if nargin < 2
    quality = 1;                    % default value for quality
end 
if quality <= 0
    error('Input parameter QUALITY must be greater than zero.');
end

m = [16 11 10 16 24 40 51 61        % default JPEG normalizing array
     12 12 14 19 26 58 60 55        % and zig-zag reordering pattern
     14 13 16 24 40 57 69 56 
     14 17 22 29 51 87 80 62
     18 22 37 56 68 109 103 77
     24 35 55 64 81 104 113 92 
     49 64 78 87 103 121 120 101 
     72 92 95 98 112 100 103 99] * quality;

order = [1 9 2 3 10 17 25 18 11 4 5 12 19 26 33  ...
         41 34 27 20 13 6 7 14 21 28 35 42 49 57 50 ...
         43 36 29 22 15 8 16 23 30 37 44 51 58 59 52 ...
         45 38 31 24 32 39 46 53 60 61 54 47 40 48 55 ...
         62 63 56 64];

[xm, xn] = size(x);                 % retrieve size of input image
x = double(x) - 128;                % level shift input                        
t = dctmtx(8);                      % compute 8 x 8 DCT matrix

% Compute DCTs pf 8 x 8 blocks and quantize coefficients 
y = blkproc(x, [8 8], 'P1 * x * P2', t, t');
y = blkproc(y, [8 8], 'round(x ./ P1)', m);  % <== nearly all elements from y are zero after this step
y = im2col(y, [8 8], 'distinct');   % break 8 x 8 blocks into columns
xb = size(y, 2);                    % get number of blocks
y = y(order, :);                    % reorder column elements

eob = max(x(:)) + 1;                % create end-of-block symbol
r = zeros(numel(y) + size(y, 2), 1);   
count = 0;

for j = 1:xb                        % process one block(one column) at a time
    i = find(y(:, j), 1, 'last');   % find last non-zero element
    if isempty(i)                   % check if there are no non-zero values
        i = 0; 
    end 
    p = count + 1;
    q = p + i;
    r(p:q)  = [y(1:i, j); eob];     % truncate trailing zeros, add eob
    count = count + i + 1;          % and add to output vector
end

r((count + 1):end) = [];            % delete unused portion of r

y           = struct;
y.size      = uint16([xm xn]);
y.numblocks = uint16(xb);
y.quality   = uint16(quality * 100);
y.huffman   = mat2huff(r); 

mat2huff is implemented as:

*mat2huff.m*
function y = mat2huff(x)
%MAT2HUFF Huffman encodes a matrix.
% Y = mat2huff(X) Huffman encodes matrix X using symbol
% probabilities in unit-width histogram bins between X's minimum
% and maximum value s. The encoded data is returned as a structure
% Y :
% Y.code           the Huffman - encoded values of X, stored in
%                  a uint16 vector. The other fields of Y contain
%                  additional decoding information , including :
% Y.min            the minimum value of X plus 32768
% Y.size           the size of X
% Y.hist           the histogram of X
% 
% If X is logical, uintB, uint16 ,uint32 ,intB ,int16, or double,
% with integer values, it can be input directly to MAT2HUF F. The
% minimum value of X must be representable as an int16.
%
% If X is double with non - integer values --- for example, an image
% with values between O and 1 --- first scale X to an appropriate
% integer range before the call.For example, use Y
% MAT2HUFF (255 * X) for 256 gray level encoding.
%
% NOTE : The number of Huffman code words is round(max(X(:)))
% round (min(X(:)))+1. You may need to scale input X to generate
% codes of reasonable length. The maximum row or column dimension
% of X is 65535.

if ~ismatrix(x) || ~isreal(x) || (~isnumeric(x) && ~islogical(x))
    error('X must be a 2-D real numeric or logical matrix.');
end
% Store the size of input x.
y.size = uint32(size(x));
% Find the range of x values
% by +32768 as a uint16.
x = round(double(x));
xmin = min(x(:));
xmax = max(x(:));
pmin = double(int16(xmin));
pmin = uint16(pmin+32768);
y.min = pmin;
% Compute the input histogram between xmin and xmax with unit
% width bins , scale to uint16 , and store.
x = x(:)';
h = histc(x, xmin:xmax);
if max(h) > 65535
    h = 65535 * h / max(h);
end
h = uint16(h); 
y.hist = h;
% Code the input mat rix and store t h e r e s u lt .
map = huffman(double(h));            % Make Huffman code map
hx = map(x(:) - xmin + 1);           % Map image
hx = char(hx)';                      % Convert to char array
hx = hx(:)';
hx(hx == ' ') = [ ];                 % Remove blanks
ysize = ceil(length(hx) / 16);       % Compute encoded size
hx16 = repmat('0', 1, ysize * 16);   % Pre-allocate modulo-16 vector
hx16(1:length(hx)) = hx;             % Make hx modulo-16 in length
hx16 = reshape(hx16, 16, ysize);     % Reshape to 16-character words
hx16 = hx16' - '0';                  % Convert binary string to decimal
twos = pow2(15 : - 1 : 0);
y.code = uint16(sum(hx16 .* twos(ones(ysize ,1), :), 2))';

