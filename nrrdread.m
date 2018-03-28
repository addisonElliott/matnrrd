function [data, meta] = nrrdread(varargin)
%NRRDREAD  Read NRRD file and metadata.
%   [X, META] = NRRDREAD(FILENAME) reads the image volume and associated
%   metadata from the NRRD-format file specified by FILENAME.
%
%   Example:
%
%       [data, metadata] = nrrdread('test.nrrd');
%
%   Special syntaxes: 
%   
%   [...] = NRRDREAD(..., 'SupressWarnings', false) will suppress any warnings
%   that occur during reading the NRRD file.
%
%   [...] = NRRDREAD(..., 'FlipDomain', true/false) determines whether the
%   data will be flipped along two axes to accomodate for the fact that
%   NRRD files are stored as row-major but MATLAB utilizes column-major
%   syntax. False will not flip the data and return it as it is read in.
%   True will attempt to flip the data. If the kinds metadata field is set,
%   then the two axes flipped are the first two 'domains', otherwise it is
%   set to be the first two axes.
%
%   Include notes about the spacedirections field! TODO Do in Remarks
%
%   Current limitations/caveats:
%   * "Block" datatype is not supported.
%   * Only tested with "gzip" and "raw" file encodings.
%   * Very limited testing on actual files.
%
%   See the format specification online:
%   http://teem.sourceforge.net/nrrd/format.html

% Input parser for parsing input commands
p = inputParser;

addRequired(p, 'filename', @isstr);
addParameter(p, 'SuppressWarnings', true, @islogical);
addParameter(p, 'FlipAxes', true, @islogical);
addParameter(p, 'Endian', [], @(x) any(strcmp({'little', 'l', 'L', 'big', ...
                                    'b', 'B'}, x)));

parse(p, varargin{:});

% Open file
[fid, msg] = fopen(p.Results.filename, 'rb');
assert(fid > 3, ['Could not open file: ' msg]);
cleaner = onCleanup(@() fclose(fid));

% Handle Magic line
magicStr = fgetl(fid);
assert(numel(magicStr) >= 4, 'Bad signature in file.')
assert(isequal(magicStr(1:4), 'NRRD'), 'Bad signature in file.')
assert(str2double(magicStr(5:end)) <= 5, 'NRRD file version too new.')

% The general format of a NRRD file (with attached header) is:
% 
%     NRRD000X
%     <field>: <desc>
%     <field>: <desc>
%     # <comment>
%     ...
%     <field>: <desc>
%     <key>:=<value>
%     <key>:=<value>
%     <key>:=<value>
%     # <comment>
% 
%     <data><data><data><data><data><data>...

meta = struct([]);
fieldMap = {};

% Parse the file a line at a time
while (true)
    lineStr = fgetl(fid);
    
    % Check for the end of the header
    if (isempty(lineStr) || feof(fid))
        break;
    end

    % Comments start with '#', skip these lines
    if (isequal(lineStr(1), '#'))
        continue;
    end

    % "fieldname:= value" or "fieldname: value" or "fieldname:value"
    parsedLine = regexp(lineStr, ':=?\s*', 'split', 'once');
    assert(numel(parsedLine) == 2, 'Parsing error')

    field = lower(parsedLine{1});
    value = parsedLine{2};

    if any(isspace(field))
        oldField = field;
        field(isspace(field)) = '';
        fieldMap = [fieldMap; {field oldField}];
    end

    meta(1).(field) = parseFieldValue(field, value, p.Results.SuppressWarnings);
end

if ~isempty(fieldMap)
    meta(1).fieldMap = fieldMap;
end

% TODO Check what the required fields are and default values

% Get the size of the data
assert(isfield(meta, 'sizes') && ...
       isfield(meta, 'dimension') && ...
       isfield(meta, 'encoding') && ...
       isfield(meta, 'type'), ...
       'Missing required metadata fields.')

% Set the default endianness if not defined in file
% If an endianness was specified as a parameter to this function, then use
% that specified endianness. Otherwise, use endianness of computer's
% architecture
if ~isfield(meta, 'endian')
    if ~isempty(p.Results.Endian)
        if any(strcmp({'little', 'l', 'L'}, p.Results.Endian))
            meta.endian = 'little';
        else
            meta.endian = 'big';
        end
    else
        [~, ~, endian] = computer();

        if endian == 'L' 
            meta.endian = 'little';
        else 
            meta.endian = 'big';
        end
    end
end

assert(length(meta.sizes) == meta.dimension);

data = readData(fid, meta);
data = adjustEndian(data, meta);

% Reshape the matrix if it has more than 1 dimension
if meta.dimension > 1
    data = reshape(data, meta.sizes);
end

% NRRD states that the dimensions specified are set in terms of the fastest
% dimension to the slowest changing dimension
% This is coined traditional C-ordering in memory but MATLAB uses Fortran
% ordering which is the opposite.
% Thus, if FlipAxes is set, the axes are flipped to correct this
if p.Results.FlipAxes
    % Get order of dimensions by reversing them
    % Permute data
    order = fliplr(1:ndims(data));
    data = permute(data, order);
end


function datatype = getDatatype(nrrdDataType)

% Determine the datatype
switch (nrrdDataType)
    case {'signed char', 'int8', 'int8_t'}
        datatype = 'int8';

    case {'uchar', 'unsigned char', 'uint8', 'uint8_t'}
        datatype = 'uint8';

    case {'short', 'short int', 'signed short', 'signed short int', ...
    'int16', 'int16_t'}
        datatype = 'int16';

    case {'ushort', 'unsigned short', 'unsigned short int', 'uint16', ...
    'uint16_t'}
        datatype = 'uint16';

    case {'int', 'signed int', 'int32', 'int32_t'}
        datatype = 'int32';

    case {'uint', 'unsigned int', 'uint32', 'uint32_t'}
        datatype = 'uint32';

    case {'longlong', 'long long', 'long long int', 'signed long long', ...
    'signed long long int', 'int64', 'int64_t'}
        datatype = 'int64';

    case {'ulonglong', 'unsigned long long', 'unsigned long long int', ...
    'uint64', 'uint64_t'}
        datatype = 'uint64';

    case {'float'}
        datatype = 'single';

    case {'double'}
        datatype = 'double';

    otherwise
        assert(false, 'Unknown datatype')
end
end


function newValue = parseFieldValue(field, value, suppressWarnings)

switch (field)
    % Handle 32-bit ints
    case {'dimension', 'lineskip', 'byteskip', 'spacedimension'}
        newValue = int32(str2double(value));

    % Handle doubles
    case {'min', 'max', 'oldmin', 'oldmax'}
        newValue = str2double(value);

    % Handle type string
    case {'type'}
        newValue = getDatatype(value);

    % Handle strings
    case {'endian', 'encoding', 'content', 'sampleunits', 'datafile', 'space'}
        newValue = lower(value);

    % Handle vectors that should have int datatype
    case {'sizes'}
        values = strsplit(value, ' ');
        newValue = int32(cellfun(@str2double, values));

    % Handle vectors that should have double datatype
    case {'spacings', 'thicknesses', 'axismins', 'axismaxs'}
        values = strsplit(value, ' ');
        newValue = cellfun(@str2double, values);

    % Handle array of strings
    case {'kinds', 'labels', 'units', 'spaceunits', 'centerings'}
        % Some array of strings have quotations around the words, probably
        % because the items can have spaces in the names and then the space
        % delimeter idea breaks down.
        % If there is a quotation mark anywhere in the string, then it
        % assumes there is quotations around each word. Otherwise, use
        % space as the delimeter
        if any(value == '"')
            newValue = lower(strsplit(value, '" "'));
            newValue{1}(1) = [];
            newValue{end}(end) = [];
        else
            newValue = lower(strsplit(value, ' '));
        end

    % Handle matrices of double datatype
    case {'spacedirections', 'spaceorigin'}
        values = strsplit(value, ' ');

        noneDim = [];

        for k = 1:length(values)
            % If a particular dimension has none, then set the row equal to
            % NaN so that it can be distinguished later on
            if strcmp(values{k}, 'none')
                noneDim = [noneDim k];
                continue;
            end

            % Remove first and last parantheses from string and then split by comma
            rowValues = strsplit(values{k}(2:end - 1), ',');

            % Take split values and turn into a vector of doubles, concatenate to
            % the matrix
            newValue(k, :) = cellfun(@str2double, rowValues);
        end

        % Set all dimensions that were none to NaN to indicate these are
        % not relevant
        newValue(noneDim, :) = NaN;

    % Handle matrices of int datatype
    case {'measurementframe'}
        values = strsplit(value, ' ');

        noneDim = [];

        for k = 1:length(values)
            % If a particular dimension has none, then set the row equal to
            % NaN so that it can be distinguished later on
            if strcmp(values{k}, 'none')
                noneDim = [noneDim k];
                continue;
            end

            % Remove first and last parantheses from string and then split by comma
            rowValues = strsplit(values{k}(2:end - 1), ',');

            % Take split values and turn into a vector of doubles, concatenate to
            % the matrix
            newValue(k, :) = cellfun(@(x) int32(str2double(x)), rowValues);
        end

        % Set all dimensions that were none to NaN to indicate these are
        % not relevant
        newValue(noneDim, :) = NaN;

    otherwise
        if ~suppressWarnings
            warning(['Unknown field ' field]);
        end
        newValue = value;
end
end


function data = readData(fidIn, meta)

switch (meta.encoding)
    case {'raw'}
        data = fread(fidIn, inf, [meta.type '=>' meta.type]);

    case {'gzip', 'gz'}
        % Create and open temporary file to store the GZIP file to be
        % decompressed
        tmpBase = tempname();
        tmpFile = [tmpBase '.gz'];
        fidTmp = fopen(tmpFile, 'wb');
        assert(fidTmp > 3, 'Could not open temporary file for GZIP decompression')

        % Read data from file and place into temporary file
        tmp = fread(fidIn, inf, 'uint8=>uint8');
        fwrite(fidTmp, tmp, 'uint8');
        fclose(fidTmp);

        % Unzip the temporary file now
        gunzip(tmpFile)

        % Open the unzipped file
        fidTmp = fopen(tmpBase, 'rb');
        cleaner = onCleanup(@() fclose(fidTmp));

        % Read the data from the unzipped file
        data = fread(fidTmp, inf, [meta.type '=>' meta.type]);

    case {'txt', 'text', 'ascii'}
        data = fscanf(fidIn, '%f');
        data = cast(data, meta.type);

    otherwise
        assert(false, 'Unsupported encoding')
end
end


function data = adjustEndian(data, meta)

[~, ~, endian] = computer();

% Note: Do not swap endianness for ASCII encoding!
needToSwap = ~any(strcmp(meta.encoding, {'txt', 'text', 'ascii'})) && ...
             ((isequal(endian, 'B') && isequal(meta.endian, 'little')) || ...
             (isequal(endian, 'L') && isequal(meta.endian, 'big')));

if (needToSwap)
    data = swapbytes(data);
end
end
end