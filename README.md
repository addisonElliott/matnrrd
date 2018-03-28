matnrrd
========
matnrrd is a MATLAB library that provides easy-to-use functions for loading and saving [NRRD](http://teem.sourceforge.net/nrrd/) files. One feature that sets matnrrd apart from other NRRD readers is that it parses the metadata fields into sensible datatypes.

Installation
------------

Download this repository and copy/paste nrrdread.m and nrrdwrite.m somewhere in your MATLAB path. You are ready to go!

Running Tests
-------------

Download the entire repository and run test.m script.

Example usage
-------------

```matlab
[data, metadata] = nrrdread('data/test1d_ascii.nrrd');
metadata.encoding = 'raw';

nrrdwrite('test.nrrd', data, metadata);
```

Documentation
-------------
See help of nrrdread and nrrdwrite for more information on how to use these functions.

License
-------

See [LICENSE](https://github.com/addisonElliott/matnrrd/blob/master/LICENSE)
