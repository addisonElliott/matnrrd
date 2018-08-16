function [data, meta] = nrrdread(varargin)
%NRRDREAD  Read NRRD file and metadata.
%   [X, META] = NRRDREAD(FILENAME, ...) reads the image volume and 
%   associated metadata from the NRRD-format file specified by FILENAME.
%
%
%   Examples:
%
%       [data, metadata] = nrrdread('data/test1d_ascii.nrrd');
%       [data, metadata] = nrrdread('data/test3d_bigendian_raw_noendianfield.nrrd', 'Endian', 'big');
%
%
%   METADATA
%
%   One of the main advantages of this function is that the metadata is
%   parsed from strings and turned into a sensible datatype. This is
%   performed for the fields specified in the NRRD specification.
%
%   A structure is used to store the metadata fields in MATLAB. One caveat
%   of using a structure is that the keys cannot have spaces in them.
%   Since the NRRD format includes fields with spaces, the spaces are
%   removed when reading. A fieldMap key is added to the structure that
%   contains a Nx2 cell array. The first column signifies the key name in
%   the MATLAB metadata structure and the second column contains the actual
%   field name with spaces. This preserves the spaces in field names when
%   using nrrdwrite to save an NRRD file.
%
%   Here is a list of supported fields and their corresponding MATLAB 
%   datatype they are converted to:
%       * dimension - int   [REQUIRED]
%       * lineskip - int
%       * byteskip - int
%       * space dimension - int
%       * min - double
%       * max - double
%       * oldmin - double
%       * oldmax - double
%       * type - string [REQUIRED]
%       * endian - string
%       * encoding - string [REQUIRED]
%       * content - string
%       * sampleunits - string
%       * datafile - string
%       * space - string
%       * sizes - 1xN matrix of ints    [REQUIRED]
%       * spacings - 1xN matrix of doubles
%       * thicknesses - 1xN matrix of doubles
%       * axismins - 1xN matrix of doubles
%       * axismaxs - 1xN matrix of doubles
%       * kinds - Nx1 cell array of strings
%       * labels - Nx1 cell array of strings
%       * units - Nx1 cell array of strings
%       * spaceunits - Nx1 cell array of strings
%       * centerings - Nx1 cell array of strings
%       * spacedirections - MxN matrix of doubles
%       * spaceorigin - MxN matrix of doubles
%       * measurementframe - MxN matrix of ints
%
%   Most of the fields listed in the table above are optional with the
%   exception of four. The NRRD file must contain the type, dimension,
%   sizes and encoding fields.
%
%   The NRRD specification allows custom entries denoted as key/value
%   pairs which are the same as fields. These custom fields are read as
%   strings unless their datatype is given in the CustomFieldMap, in which
%   case the field will be parsed to the data type. See the CustomFieldMap
%   note in Special Syntaxes for more information
%
%   Note: For spacedirections, NRRD allows specifying none for a
%   particular dimension to indicate it is not a spatial domain.
%   NRRDREAD will make the first row of the matrix all NaN's to signal
%   that it is none for the dimension. For example:
%       space directions: none (1,0,0) (0,1,0) (0,0,1)
%   will turn into:
%       [NaN NaN NaN; 1 0 0; 0 1 0; 0 0 1]
%
%   For unsupported fields, a warning will be displayed and the value will
%   be left as a string.
%
%
%   Special syntaxes: 
%   
%   [...] = NRRDREAD(..., 'SupressWarnings', true/false) suppresses any
%   warnings that occur while reading if set to true. Otherwise, if false,
%   warnings will be printed to console. The typical warnings are for
%   field/value in the NRRD metadata that are unknown. Set to true by
%   default.
%
%   [...] = NRRDREAD(..., 'Endian', 'big'/'b'/'little'/'l') sets the
%   endianness of the file if it is not specified in the file itself. If
%   this field is empty, then the endianness of the current machine will
%   be used. This parameter is useful when a NRRD file was created on a
%   machine with a different endianness but the endianness is not specified
%   in the NRRD file itself. 
%
%   [...] = NRRDREAD(..., 'CustomFieldMap', Nx2 Cell matrix) indicates what 
%   datatype custom fields should be parsed as. Each row of the field map
%   is considered an entry where the first column is the field name WITH
%   SPACES REMOVED and the second column is a string identifying the 
%   datatype. The list of valid datatypes are:
%
%   Datatype        Example Syntax in NRRD File
%   -------------------------------------------
%   int             5
%   double          2.5
%   string          testing
%   int list        1 2 3 4 5
%   double list     1.2 2.0 3.1 4.7 5.0
%   string list     first second third
%   int vector      (1,0,0)
%   double vector   (3.14,3.14,6.28)
%   int matrix      (1,0,0) (0,1,0) (0,0,1)
%   double matrix   (1.2,0.3,0) (0,1.5,0) (0,-0.55,1.6)
%
%   Here is an example custom field map:
%       nrrdread(..., 'CustomFieldMap', {'version' 'string'; 
%                   'color' 'int vector'; 'test' 'double matrix'})
%
%
%   REMARKS
%
%   The NRRD specification states that the data array is stored in memory 
%   with what is coined as C-order style. However, MATLAB stores arrays in 
%   Fortran-order style. The key distinction between these two styles is
%   that the horizontal and vertical (i.e. x and y) dimensions will be 
%   flipped. The typical solution to this problem is to use PERMUTE to
%   switch the horizontal and vertical dimensions.
%
%   In addition, for NRRD files with color information, the color dimension
%   will be at the front of the array. The normal convention is to have the
%   color component be the last dimension. This can be fixed using PERMUTE
%   to move the first dimension to the end.
%
%
%   MORE INFORMATION
%
%   Help out by reporting bugs or contributing code at:
%       https://github.com/addisonElliott/matnrrd
%
%   See the format specification online:
%       http://teem.sourceforge.net/nrrd/format.html
%
%    See also nrrdwrite, imread, xlsread.

% Input parser for parsing input commands
p = inputParser;

addRequired(p, 'filename', @isstr);
addParameter(p, 'SuppressWarnings', true, @islogical);
addParameter(p, 'Endian', [], @(x) any(strcmp({'little', 'l', 'L', 'big', ...
                                    'b', 'B'}, x)));
addParameter(p, 'CustomFieldMap', {}, @(x) iscell(x) && ismatrix(x) && ...
                                    (isempty(x) || size(x, 2) == 2)); 
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

    % "key:= value" or "fieldname: value" or "fieldname:value"
    % Note: key/value pair is treated the same as field/value pair
    parsedLine = regexp(lineStr, ':=?\s*', 'split', 'once');
    assert(numel(parsedLine) == 2, 'Parsing error')

    field = lower(parsedLine{1});
    value = parsedLine{2};

    if any(isspace(field))
        oldField = field;
        field(isspace(field)) = '';
        fieldMap = [fieldMap; {field oldField}];
    end

    type = getFieldType(field, p.Results.CustomFieldMap, p.Results.SuppressWarnings);

    meta(1).(field) = parseFieldValue(value, type, p.Results.SuppressWarnings);
end

if ~isempty(fieldMap)
    meta(1).fieldMap = fieldMap;
end

% Check that required fields are present
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


function newValue = parseFieldValue(value, type, suppressWarnings)
% Parse a field value based on its given type
%
% Type is one of the following strings indicating it's type:
%   int
%   datatype
%   double
%   string
%   int list
%   double list
%   string list
%   int vector
%   double vector
%   int matrix
%   double matrix

switch (type)
    case {'int'}
        newValue = int32(str2double(value));

    case {'double'}
        newValue = str2double(value);

    case {'string'}
        newValue = lower(value);

    case {'datatype'}
        newValue = getDatatype(value);

    case {'int list'}
        values = strsplit(value, ' ');
        newValue = int32(cellfun(@str2double, values));

    case {'double list'}
        values = strsplit(value, ' ');
        newValue = cellfun(@str2double, values);

    case {'string list'}
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

    case {'int vector'}
        % Remove first and last parantheses from string and then split by comma
        rowValues = strsplit(value(2:end - 1), ',');

        % Take split values and turn into a vector of doubles, concatenate to
        % the matrix
        newValue = cellfun(@(x) int32(str2double(x)), rowValues);

    case {'double vector'}
        % Remove first and last parantheses from string and then split by comma
        rowValues = strsplit(value(2:end - 1), ',');

        % Take split values and turn into a vector of doubles, concatenate to
        % the matrix
        newValue = cellfun(@str2double, rowValues);

    % Handle matrices of int datatype
    case {'int matrix'}
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

    % Handle matrices of double datatype
    case {'double matrix'}
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

    otherwise
        if ~suppressWarnings
            warning(['Unknown type ' type]);
        end
        newValue = value;
end
end


function type = getFieldType(field, customFieldValueMap, suppressWarnings)
switch (field)
    % Handle 32-bit ints
    case {'dimension', 'lineskip', 'byteskip', 'spacedimension'}
        type = 'int';

    % Handle doubles
    case {'min', 'max', 'oldmin', 'oldmax'}
        type = 'double';

    % Handle type string
    case {'type'}
        type = 'datatype';

    % Handle strings
    case {'endian', 'encoding', 'content', 'sampleunits', 'datafile', 'space'}
        type = 'string';

    % Handle vectors that should have int datatype
    case {'sizes'}
        type = 'int list';

    % Handle vectors that should have double datatype
    case {'spacings', 'thicknesses', 'axismins', 'axismaxs'}
        type = 'double list';

    % Handle array of strings
    case {'kinds', 'labels', 'units', 'spaceunits', 'centerings'}
        type = 'string list';

    case {'spaceorigin'}
        type = 'double vector';

    % Handle matrices of double datatype
    case {'spacedirections'}
        type = 'double matrix';

    % Handle matrices of int datatype
    case {'measurementframe'}
        type = 'int matrix';

    otherwise
        if isempty(customFieldValueMap)
            customFieldIndex = [];
        else
            customFieldIndex = find(strcmp(customFieldValueMap(:, 1), field));
        end

        if ~isempty(customFieldIndex)
            type = customFieldValueMap{customFieldIndex, 2};
        else
            if ~suppressWarnings
                warning(['Unknown field ' field '. If this is a known ' ...
                        'custom field then specify the type in the ' ...
                        'customFieldValueMap']);
            end

            % Default the type to string because it is a string by default
            type = 'string';
        end
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

% Note: Do not swap bytes for ASCII encoding!
needToSwap = ~any(strcmp(meta.encoding, {'txt', 'text', 'ascii'})) && ...
             ((isequal(endian, 'B') && isequal(meta.endian, 'little')) || ...
             (isequal(endian, 'L') && isequal(meta.endian, 'big')));

if (needToSwap)
    data = swapbytes(data);
end
end
end