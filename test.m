[data, metadata] = nrrdread('data/test1d_ascii.nrrd');

assert(all(data == (1:27)'), 'Invalid data matrix for test1d');
assert(metadata.dimension == 1, 'Dimension is not 1 for test1d');
assert(strcmp(metadata.type, 'uint8'), 'Type is not uint8 for test1d');
assert(metadata.sizes == 27, 'Vector length is not 27 for test1d');
assert(strcmp(metadata.encoding, 'ascii'), 'Not ASCII encoding for test1d');


[data, metadata] = nrrdread('data/test2d_ascii.nrrd');

assert(all(all(data == reshape(1:27, [3 9]))), 'Invalid data matrix for test2d');
assert(metadata.dimension == 2, 'Dimension is not 2 for test2d');
assert(strcmp(metadata.type, 'uint16'), 'Type is not uint16 for test2d');
assert(all(metadata.sizes == [3 9]), 'Sizes not right for test2d');
assert(strcmp(metadata.encoding, 'ascii'), 'Not ASCII encoding for test2d');
assert(metadata.spacedimension == 2, 'Space dimension is not 2 for test2d');
assert(all(metadata.spacings == [1.0458 2]), 'Spacing not correct for test2d');
assert(all(isnan(metadata.spacedirections)), 'Space directions not correct for test2d');
assert(all(strcmp(metadata.kinds, 'domain')), 'Kinds not correct for test2d');
assert(all(strcmp(metadata.spaceunits, 'mm')), 'Space units not correct for test2d');
assert(all(metadata.spaceorigin == [100 200]), 'Space origin not correct for test2d');


[data, metadata] = nrrdread('data/test3d_ascii.nrrd');

assert(all(all(all(data == reshape(1:27, [3 3 3])))), 'Invalid data matrix for test3d');
assert(metadata.dimension == 3, 'Dimension is not 3 for test3d');
assert(strcmp(metadata.type, 'uint32'), 'Type is not uint32 for test3d');
assert(all(metadata.sizes == [3 3 3]), 'Sizes not right for test3d');
assert(strcmp(metadata.encoding, 'ascii'), 'Not ASCII encoding for test3d');
assert(strcmp(metadata.space, 'left-posterior-superior'), 'Space not right for test3d');
assert(all(all(metadata.spacedirections == [1 0 0; 0 1 0; 0 0 1])), 'Space directions not correct for test3d');
assert(all(strcmp(metadata.kinds, 'domain')), 'Kinds not correct for test3d');
assert(all(strcmp(metadata.spaceunits, 'mm')), 'Space units not correct for test3d');
assert(all(metadata.spaceorigin == [100.1 200.3 -500]), 'Space origin not correct for test3d');


[data, metadata] = nrrdread('data/test1d_raw.nrrd');

assert(all(data == (1:27)'), 'Invalid data matrix for test1d');
assert(metadata.dimension == 1, 'Dimension is not 1 for test1d');
assert(strcmp(metadata.type, 'uint8'), 'Type is not uint8 for test1d');
assert(metadata.sizes == 27, 'Vector length is not 27 for test1d');
assert(strcmp(metadata.encoding, 'raw'), 'Not raw encoding for test1d');


[data, metadata] = nrrdread('data/test2d_raw.nrrd');

assert(all(all(data == reshape(1:27, [3 9]))), 'Invalid data matrix for test2d');
assert(metadata.dimension == 2, 'Dimension is not 2 for test2d');
assert(strcmp(metadata.type, 'uint16'), 'Type is not uint16 for test2d');
assert(all(metadata.sizes == [3 9]), 'Sizes not right for test2d');
assert(strcmp(metadata.encoding, 'raw'), 'Not raw encoding for test2d');
assert(metadata.spacedimension == 2, 'Space dimension is not 2 for test2d');
assert(all(metadata.spacings == [1.0458 2]), 'Spacing not correct for test2d');
assert(all(isnan(metadata.spacedirections)), 'Space directions not correct for test2d');
assert(all(strcmp(metadata.kinds, 'domain')), 'Kinds not correct for test2d');
assert(all(strcmp(metadata.spaceunits, 'mm')), 'Space units not correct for test2d');
assert(all(metadata.spaceorigin == [100 200]), 'Space origin not correct for test2d');


[data, metadata] = nrrdread('data/test3d_raw.nrrd');

assert(all(all(all(data == reshape(1:27, [3 3 3])))), 'Invalid data matrix for test3d');
assert(metadata.dimension == 3, 'Dimension is not 3 for test3d');
assert(strcmp(metadata.type, 'uint32'), 'Type is not uint32 for test3d');
assert(all(metadata.sizes == [3 3 3]), 'Sizes not right for test3d');
assert(strcmp(metadata.encoding, 'raw'), 'Not raw encoding for test3d');
assert(strcmp(metadata.space, 'left-posterior-superior'), 'Space not right for test3d');
assert(all(all(metadata.spacedirections == [1 0 0; 0 1 0; 0 0 1])), 'Space directions not correct for test3d');
assert(all(strcmp(metadata.kinds, 'domain')), 'Kinds not correct for test3d');
assert(all(strcmp(metadata.spaceunits, 'mm')), 'Space units not correct for test3d');
assert(all(metadata.spaceorigin == [100.1 200.3 -500]), 'Space origin not correct for test3d');


% Test big endian for ASCII - should have no effect
[data, metadata] = nrrdread('data/test3d_ascii.nrrd');
metadata.endian = 'big';

assert(all(all(all(data == reshape(1:27, [3 3 3])))), 'Invalid data matrix for test3d');
assert(metadata.dimension == 3, 'Dimension is not 3 for test3d');
assert(strcmp(metadata.type, 'uint32'), 'Type is not uint32 for test3d');
assert(all(metadata.sizes == [3 3 3]), 'Sizes not right for test3d');
assert(strcmp(metadata.encoding, 'ascii'), 'Not ASCII encoding for test3d');
assert(strcmp(metadata.space, 'left-posterior-superior'), 'Space not right for test3d');
assert(all(all(metadata.spacedirections == [1 0 0; 0 1 0; 0 0 1])), 'Space directions not correct for test3d');
assert(all(strcmp(metadata.kinds, 'domain')), 'Kinds not correct for test3d');
assert(all(strcmp(metadata.spaceunits, 'mm')), 'Space units not correct for test3d');
assert(all(metadata.spaceorigin == [100.1 200.3 -500]), 'Space origin not correct for test3d');


% Test big endian for raw encoding
[data, metadata] = nrrdread('data/test3d_bigendian_raw.nrrd');

assert(all(all(all(data == reshape(1:27, [3 3 3])))), 'Invalid data matrix for test3d');
assert(metadata.dimension == 3, 'Dimension is not 3 for test3d');
assert(strcmp(metadata.type, 'uint32'), 'Type is not uint32 for test3d');
assert(all(metadata.sizes == [3 3 3]), 'Sizes not right for test3d');
assert(strcmp(metadata.encoding, 'raw'), 'Not raw encoding for test3d');
assert(strcmp(metadata.endian, 'big'), 'Not big endian for test3d');
assert(strcmp(metadata.space, 'left-posterior-superior'), 'Space not right for test3d');
assert(all(all(metadata.spacedirections == [1 0 0; 0 1 0; 0 0 1])), 'Space directions not correct for test3d');
assert(all(strcmp(metadata.kinds, 'domain')), 'Kinds not correct for test3d');
assert(all(strcmp(metadata.spaceunits, 'mm')), 'Space units not correct for test3d');
assert(all(metadata.spaceorigin == [100.1 200.3 -500]), 'Space origin not correct for test3d');


% Test big endian for raw encoding, but this time no endian metadata field
% will be present. Need to force the endianness
[data, metadata] = nrrdread('data/test3d_bigendian_raw_noendianfield.nrrd', 'Endian', 'big');

assert(all(all(all(data == reshape(1:27, [3 3 3])))), 'Invalid data matrix for test3d');
assert(metadata.dimension == 3, 'Dimension is not 3 for test3d');
assert(strcmp(metadata.type, 'uint32'), 'Type is not uint32 for test3d');
assert(all(metadata.sizes == [3 3 3]), 'Sizes not right for test3d');
assert(strcmp(metadata.encoding, 'raw'), 'Not raw encoding for test3d');
assert(strcmp(metadata.endian, 'big'), 'Not big endian for test3d');
assert(strcmp(metadata.space, 'left-posterior-superior'), 'Space not right for test3d');
assert(all(all(metadata.spacedirections == [1 0 0; 0 1 0; 0 0 1])), 'Space directions not correct for test3d');
assert(all(strcmp(metadata.kinds, 'domain')), 'Kinds not correct for test3d');
assert(all(strcmp(metadata.spaceunits, 'mm')), 'Space units not correct for test3d');
assert(all(metadata.spaceorigin == [100.1 200.3 -500]), 'Space origin not correct for test3d');


[data, metadata] = nrrdread('data/test1d_gzip.nrrd');

assert(all(data == (1:27)'), 'Invalid data matrix for test1d');
assert(metadata.dimension == 1, 'Dimension is not 1 for test1d');
assert(strcmp(metadata.type, 'uint8'), 'Type is not uint8 for test1d');
assert(metadata.sizes == 27, 'Vector length is not 27 for test1d');
assert(strcmp(metadata.encoding, 'gzip'), 'Not gzip encoding for test1d');


[data, metadata] = nrrdread('data/test2d_gzip.nrrd');

assert(all(all(data == reshape(1:27, [3 9]))), 'Invalid data matrix for test2d');
assert(metadata.dimension == 2, 'Dimension is not 2 for test2d');
assert(strcmp(metadata.type, 'uint16'), 'Type is not uint16 for test2d');
assert(all(metadata.sizes == [3 9]), 'Sizes not right for test2d');
assert(strcmp(metadata.encoding, 'gzip'), 'Not gzip encoding for test2d');
assert(metadata.spacedimension == 2, 'Space dimension is not 2 for test2d');
assert(all(metadata.spacings == [1.0458 2]), 'Spacing not correct for test2d');
assert(all(isnan(metadata.spacedirections)), 'Space directions not correct for test2d');
assert(all(strcmp(metadata.kinds, 'domain')), 'Kinds not correct for test2d');
assert(all(strcmp(metadata.spaceunits, 'mm')), 'Space units not correct for test2d');
assert(all(metadata.spaceorigin == [100 200]), 'Space origin not correct for test2d');


[data, metadata] = nrrdread('data/test3d_gzip.nrrd');

assert(all(all(all(data == reshape(1:27, [3 3 3])))), 'Invalid data matrix for test3d');
assert(metadata.dimension == 3, 'Dimension is not 3 for test3d');
assert(strcmp(metadata.type, 'uint32'), 'Type is not uint32 for test3d');
assert(all(metadata.sizes == [3 3 3]), 'Sizes not right for test3d');
assert(strcmp(metadata.encoding, 'gzip'), 'Not gzip encoding for test3d');
assert(strcmp(metadata.space, 'left-posterior-superior'), 'Space not right for test3d');
assert(all(all(metadata.spacedirections == [1 0 0; 0 1 0; 0 0 1])), 'Space directions not correct for test3d');
assert(all(strcmp(metadata.kinds, 'domain')), 'Kinds not correct for test3d');
assert(all(strcmp(metadata.spaceunits, 'mm')), 'Space units not correct for test3d');
assert(all(metadata.spaceorigin == [100.1 200.3 -500]), 'Space origin not correct for test3d');