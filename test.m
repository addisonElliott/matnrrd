% [data, metadata] = nrrdread('data/test1d.nrrd');
% 
% assert(all(data == 1:27), 'Invalid data matrix for test1d');
% assert(metadata.dimension == 1, 'Dimension is not 1 for test1d');
% assert(strcmp(metadata.type, 'uint8'), 'Type is not uint8 for test1d');
% assert(metadata.sizes == 27, 'Vector length is not 27 for test1d');
% assert(strcmp(metadata.encoding, 'ascii'), 'Not ASCII encoding for test1d');

% [data, metadata] = nrrdread('data/test2d.nrrd');
% 
% assert(all(all(data == reshape(1:27, [3 9])')), 'Invalid data matrix for test2d');
% assert(metadata.dimension == 2, 'Dimension is not 2 for test2d');
% assert(strcmp(metadata.type, 'uint16'), 'Type is not uint16 for test2d');
% assert(all(metadata.sizes == [3 9]), 'Vector length is not 27 for test2d');
% assert(strcmp(metadata.encoding, 'ascii'), 'Not ASCII encoding for test2d');
% assert(metadata.spacedimension == 2, 'Space dimension is not 2 for test2d');
% assert(all(metadata.spacings == [1.0458 2]), 'Spacing not correct for test2d');
% assert(all(isnan(metadata.spacedirections)), 'Space directions not correct for test2d');
% assert(all(strcmp(metadata.kinds, 'domain')), 'Kinds not correct for test2d');
% assert(all(strcmp(metadata.spaceunits, 'mm')), 'Space units not correct for test2d');
% assert(all(metadata.spaceorigin == [100 200]), 'Space origin not correct for test2d');

% [data, metadata] = nrrdread('data/test3d.nrrd');




% filename = 'data/303PREDIASTOLE.seg.nrrd';
% filename = 'data/an-hist.nrrd';
% filename = 'data/EndDiastole.nrrd';
% filename = 'data/SCAT.nrrd';
% filename = 'unustuff/test.nrrd';

% [data, metadata] = nrrdread(filename, 'FlipDomain', false);

% nrrdwrite('test.nrrd', data, metadata);

% data = permute(data, [2 1 3]);
% data = permute(data, [2 3 4 1]);
% 
% imshow(data(:, :, 10, 1) * 255);