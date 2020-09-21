function traces = npReader(filename, nChansTotal)
% Subtracts median of each channel, then subtracts median of each time
% point.
%
% filename should include the extension
% outputDir is optional, by default will write to the directory of the input file
%
% should make chunk size as big as possible so that the medians of the
% channels differ little from chunk to chunk.
chunkSize = 1000000;

fid = []; 

d = dir(filename);
nSampsTotal = d.bytes/nChansTotal/2;
nChunksTotal = ceil(nSampsTotal/chunkSize);
try
  
  fid = fopen(filename, 'r');

  chunkInd = 1;
  traces = zeros(nChansTotal, nSampsTotal);
  while 1
    
    fprintf(1, 'chunk %d/%d\n', chunkInd, nChunksTotal);
    
    dat = fread(fid, [nChansTotal chunkSize], '*int16');
    
    chunkInd = chunkInd+1;
  end
  
  fclose(fid);
  
catch me
  
  if ~isempty(fid)
    fclose(fid);
  end
  
  rethrow(me)
  
end