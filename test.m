% filename = '303PREDIASTOLE.seg.nrrd';
filename = 'an-hist.nrrd';
% filename = 'EndDiastole.nrrd';
% filename = 'SCAT.nrrd';

[data, metadata] = nrrdread(filename);

nrrdwrite('test.nrrd', data, metadata);

% data = permute(data, [2 1 3]);
% data = permute(data, [2 3 4 1]);
% 
% imshow(data(:, :, 10, 1) * 255);