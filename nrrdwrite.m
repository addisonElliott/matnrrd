function nrrdwrite(varargin)
%NRRDWRITE  Write image volume and metadata to NRRD file.
%   NRRDWRITE(FILENAME, data, meta, ...) writes the image volume DATA and 
%   associated metadata META to a NRRD file specified by FILENAME. 
%
%
%   Example:
%
%       [data, metadata] = nrrdread('data/test1d_ascii.nrrd');
%       metadata.encoding = 'raw';
%       nrrdwrite('test.nrrd', data, metadata);
%
%
%   METADATA
%
%   META should be a structure with the field names as the key and with a
%   value. One caveat of using a structure is that the keys cannot have 
%   spaces in them. To resolve this issue, the field names should have
%   spaces removed from them before being added to the metadata structure.
%   In addition, a fieldMap key can be added to the structure and should
%   contain a Nx2 cell array. The first column indicates the key name in
%   the structure and the second column contains the actual field name to 
%   be written in the NRRD file. 
%
%   NRRDWRITE automatically handles converting from the appropiate datatype
%   of supported fields to a string for the NRRD file. Following is a list 
%   of supported fields and their corresponding MATLAB datatype they should 
%   be:
%       * dimension - int
%       * lineskip - int
%       * byteskip - int
%       * space dimension - int
%       * min - double
%       * max - double
%       * oldmin - double
%       * oldmax - double
%       * type - string
%       * endian - string [default: machine endianness]
%       * encoding - string [default: gzip]
%       * content - string
%       * sampleunits - string
%       * datafile - string
%       * space - string
%       * sizes - 1xN matrix of ints
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
%   If encoding is not set in META, then it will default to 'gzip'. If
%   endian is not set in META, then it will default to the machine's
%   endianness.
%
%   Note: For spacedirections, NRRD allows specifying none for a particular
%   dimension to indicate it is not a spatial domain.
%   NRRDWRITE will write out none for a particular dimension if that 
%   corresponding row of the matrix is all NaNs. For example: 
%       spacedirections = [NaN NaN NaN; 1 0 0; 0 1 0; 0 0 1]
%   will turn into:
%       space directions: none (1,0,0) (0,1,0) (0,0,1)
%
%   For unsupported fields, a warning will be displayed. Any unsupported
%   field's values will be directly written to the NRRD file and thus
%   should be a string.
%
%
%   Special syntaxes: 
%   
%   [...] = NRRDWRITE(..., 'SupressWarnings', true/false) suppresses any
%   warnings that occur while writing if set to true. Otherwise, if false,
%   warnings will be printed to console. The typical warnings are for
%   field/value in the NRRD metadata that are unknown. Set to true by
%   default.
%
%   [...] = NRRDWRITE(..., 'AsciiDelimeter', char) sets the character to 
%   use when delineating values. This option is only valid when the 
%   encoding is set to ascii. By default, this is set to be a newline (\n).
%
%   [...] = NRRDWRITE(..., 'UseStringVectorQuotationMarks', true/false)
%   determines whether quotation marks will be placed around string
%   vectors. This only applies to the fields: labels, spaceunits and units.
%   If set to true, then quotation marks will be used, otherwise, if false,
%   none will be used. By default, this is set to true. For example:
%       spaceunits = {'mm' 'mm' 'mm'}
%   will turn into the following if parameter is set to true:
%       space units: "mm" "mm" "mm"
%   otherwise, if set to false:
%       space units: mm mm mm
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
%   Help everyone out by reporting bugs or contributing code at:
%       https://github.com/addisonElliott/matnrrd
%
%   See the format specification online:
%       http://teem.sourceforge.net/nrrd/format.html
%
%    See also nrrdread, imwrite, xlswrite.

% Input parser for parsing input commands
p = inputParser;

addRequired(p, 'filename', @isstr);
addRequired(p, 'data', @(x) isnumeric(x) || islogical(x));
addRequired(p, 'meta', @isstruct);
addParameter(p, 'SuppressWarnings', true, @islogical);
addParameter(p, 'AsciiDelimeter', '\n', @ischar);
addParameter(p, 'UseStringVectorQuotationMarks', false, @islogical);
addParameter(p, 'CustomFieldMap', {}, @(x) iscell(x) && ismatrix(x) && ...
                                    (isempty(x) || size(x, 2) == 2)); 
parse(p, varargin{:});

filename = p.Results.filename;
data = p.Results.data;
meta = p.Results.meta;

% If encoding is not specified, set to gzip by default
if ~isfield(meta, 'encoding')
    meta.encoding = 'gzip';
end

% If endianness is not specified, set to the endianness of architecture
if ~isfield(meta, 'endian')
    [~, ~, endian] = computer();

    if endian == 'L' 
        meta.endian = 'little';
    else 
        meta.endian = 'big';
    end
end

% Set the data type, number of dimensions and size
% These fields could be out of date or incorrect, so it is best just to
% update these fields
meta.type = getNRRDDatatype(class(data));

% Handle special case of a vector because ndims returns 2 for a vector even
% though one dimension is length 1
if isvector(data)
    meta.dimension = 1;
    meta.sizes = length(data);
else
    meta.dimension = ndims(data);
    meta.sizes = fliplr(size(data));
end

% Open file for writing
fid = fopen(filename, 'wb');
assert(fid > 0, 'Could not open file.');

% Write magic string and header comments
fprintf(fid, 'NRRD0005\n');
fprintf(fid, '# This NRRD file was generated by nrrdwrite\n');
fprintf(fid, '# Complete NRRD file format specification at:\n');
fprintf(fid, '# http://teem.sourceforge.net/nrrd/format.html\n');

% Retrieve field names from metadata
fieldNames = fieldnames(meta);

% Sort field names such that it follows the field order structure. All
% fields not specified in the field order are placed at the end of the
% field names array
fieldOrder = {'type' ...
    'dimension' ...
    'spacedimension' ...
    'space' ...
    'sizes' ...
    'spacedirections' ...
    'kinds' ...
    'endian' ...
    'encoding' ...
    'min' ...
    'max' ...
    'oldmin' ...
    'old min' ...
    'oldmax' ...
    'old max' ...
    'content' ...
    'sample units' ...
    'spacings' ...
    'thicknesses' ...
    'axismins' ...
    'axismaxs' ...
    'centerings' ...
    'labels' ...
    'units' ...
    'spaceunits' ...
    'spaceorigin' ...
    'measurementframe' ...
    'datafile'};

% TODO Store custom fields (not in fieldOrder) with := instead of :
% (key/value pair)

% Loop through each of the fieldOrder fields, find it in the metadata. If
% found, then this is added to the sorted field names array and removed
% from the field names array.
sortedFieldNames = {};
for kk = 1:length(fieldOrder)
    field = fieldOrder{kk};

    idx = find(strcmp(fieldNames, field));

    if ~isempty(idx)
        sortedFieldNames = [sortedFieldNames; field];
        fieldNames(idx) = [];
    end
end

% Append sorted field names to the beginning of field names
% Any field names not found in fieldOrder will be at the back in the same
% order they were read in with nrrdread (or in order of when the field was
% updated last).
fieldNames = [sortedFieldNames; fieldNames];

% Start index for custom fields
% The custom fields come right after the sorted field names
customFieldIndex = length(sortedFieldNames);

% If fieldMap field is present in the metadata, then copy it over to a
% local variable and otherwise create an empty local variable fieldMap
% This is used to get the field name that should be written to the file. It
% is useful for fields that had spaces in them but were removed when
% reading them in (struct's fields cannot have spaces)
if isfield(meta, 'fieldMap')
    fieldMap = meta.fieldMap;
    fieldNames(strcmp(fieldNames, 'fieldMap')) = [];
else
    fieldMap = {};
end

% Loop through the sorted field names and write to file one by one
for kk = 1:length(fieldNames)
    % Get field name and the field value (converted to string)
    field = fieldNames{kk};

    type = getFieldType(field, p.Results.CustomFieldMap, p.Results.SuppressWarnings);

    value = formatFieldValue(meta.(field), type, p.Results.SuppressWarnings, p.Results.UseStringVectorQuotationMarks);

    % If the field name is present in the fieldMap, then use the mapped
    % value. This will useful for replacing spaces when writing the field
    % to the file (e.g. 'spacedirections' maps to 'space directions')
    if ~isempty(fieldMap)
        index = find(strcmp(fieldMap(:, 1), field));
        if ~isempty(index)
            field = fieldMap{index, 2};
        end
    end

    % Write the field and value to the file
    % If writing custom fields, then output as a key/value pair instead
    if kk > customFieldIndex
        fprintf(fid, '%s:= %s\n', field, value);
    else
        fprintf(fid, '%s: %s\n', field, value);
    end
end

% Append a blank space to the file to indicate data is coming next
fprintf(fid, '\n');

writeData(fid, meta, data, p.Results.AsciiDelimeter);

% Close file
cleaner = onCleanup(@() fclose(fid));


function NRRDDataType = getNRRDDatatype(dataType)

% Determine the datatype
switch (dataType)
    case {'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64' ...
            'uint64', 'double'}
        NRRDDataType = dataType;

    case {'single'}
        NRRDDataType = 'float';

    otherwise
        assert(false, 'Unknown datatype')
end
end


function [str] = getVectorStr(value, formatStr, delimeter)
    % Since num2str only works on arrays and arrays will concatenate
    % all strings together returning one large string, this causes
    % issue for variable precision on doubles. 
    % To solve this, the array is turned into a cell array, then each
    % cell is converted to a string resulting in a cell array of strings
    % Finally, the cell array is joined by a delimeter
    values = cellfun(@(x) num2str(x, formatStr), num2cell(value), 'UniformOutput', false);
    str = strjoin(values, delimeter);
end


function type = getFieldType(field, customFieldMap, suppressWarnings)
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
        % customFieldIndex is entirely different from variable in main
        % script
        if isempty(customFieldMap)
            customFieldIndex = [];
        else
            customFieldIndex = find(strcmp(customFieldMap(:, 1), field));
        end

        if ~isempty(customFieldIndex)
            type = customFieldMap{customFieldIndex, 2};
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


function str = formatFieldValue(value, type, SuppressWarnings, ...
                            UseStringVectorQuotationMarks)
% TODO Allow custom field parsing

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
% Note: It is difficult to automatically identify the type of a value
% because MATLAB saves all variables as doubles even if they are integers
% Also, number list and a vector are the same and cannot be distinguished
% based on type
% Because of this reason, each custom field must be given a type so it is
% known how to convert it

switch (type)
    case {'int'}
        str = num2str(value, '%i');

    case {'double'}
        str = num2str(value, '%.16g');

    case {'string'}
        str = value;

    case {'datatype'}
        % TODO Get datatype from the data matrix first using class(x)
        % and converting it. Then document this change.
        str = value;

    case {'int list'}
        str = getVectorStr(value, '%i', ' ');

    case {'double list'}
        str = getVectorStr(value, '%.16g', ' ');

    case {'string list'}
        % TODO Need some way to handle UseStringVectorQuotationMarks
        str = strjoin(value, ' ');

    % Vector and matrix are handled the same
    case {'int vector', 'int matrix'}
        str = '';

        for k = 1:size(value, 1)
            if all(isnan(value(k, :)))
                str = [str 'none '];
            else
                vectorStr = getVectorStr(value(k, :), '%i', ',');
                str = [str '(' vectorStr ') '];
            end
        end

        str(end) = [];

    case {'double vector', 'double matrix'}
        str = '';

        for k = 1:size(value, 1)
            if all(isnan(value(k, :)))
                str = [str 'none '];
            else
                vectorStr = getVectorStr(value(k, :), '%.16g', ',');
                str = [str '(' vectorStr ') '];
            end
        end

        str(end) = [];

    otherwise
        if ~SuppressWarnings
            warning(['Unknown type ' type]);
        end
        str = value;
end
end


function writeData(fid, meta, data, AsciiDelimeter)

switch (meta.encoding)
    case {'raw'}
        % Note: Machine format takes in l or b for little or big endian, so
        % this is accomplished by grabbing first letter from endian field
        % of metadata.
        fwrite(fid, data, class(data), 0, meta.endian(1));

    case {'gzip', 'gz'}
        % Create an open a temporary file to store the data in to be
        % compressed
        tmpFilename = tempname();
        tmpFid = fopen(tmpFilename, 'wb');
        assert(tmpFid > 3, 'Could not open temporary file for GZIP compression');

        % Write the data to the file and then close it (do not use
        % onCleanup because we NEED the file closed now to be able to zip
        % it)
        fwrite(tmpFid, data, class(data), 0, meta.endian(1));
        fclose(tmpFid);

        % Compress the data
        gzip(tmpFilename);

        % Next read the compressed file and copy data to NRRD file
        tmpFid = fopen([tmpFilename '.gz'], 'rb');
        assert(tmpFid > 3, 'Could not read GZIP compressed file');
        cleaner = onCleanup(@() fclose(tmpFid));

        % Read the data from the zipped file
        compressedData = fread(tmpFid, inf, 'uint8=>uint8');

        % Write data to NRRD file
        fwrite(fid, compressedData, 'uint8');

    case {'txt', 'text', 'ascii'}
        % Get the formatSpec string based on the data type
        % Note: Double precision can store at maximum 16 decimal places
        % Single precision can store at maximum 7 decimal places.
        switch (class(data))
            case {'double'}, formatSpec = '%.16g';
            case {'single'}, formatSpec = '%.7g';
            otherwise, formatSpec = '%i';
        end

        % Print the data matrix to the file using fprintf
        % For the special case of a 2D matrix, the ASCII text is written in
        % rows and columns to look nice.
        if meta.dimension == 2
            % Go row by row (i.e. y-value) and print the row. Follow the
            % row printing with a newline
            for y = 1:size(data, 2)
                str = getVectorStr(data(:, y), formatSpec, ' ');
                fprintf(fid, [str '\n']);
            end
        else
            % Print the data matrix using the AsciiDelimeter parameter
            formatSpec = [formatSpec AsciiDelimeter];
            fprintf(fid, formatSpec, data);
        end

    otherwise
        assert(false, 'Unsupported encoding')
end
end

end