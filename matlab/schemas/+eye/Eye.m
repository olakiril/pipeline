%{
# eye velocity and timestamps
-> `pipeline_experiment`.`scan`
---
total_frames                : int                           # total number of frames in movie.
preview_frames              : longblob                      # 16 preview frames
eye_time                    : longblob                      # timestamps of each frame in seconds, with same t=0 as patch and ball data
eye_ts=CURRENT_TIMESTAMP    : timestamp                     # automatic
%}


classdef Eye < dj.Imported

	methods(Access=protected)

		function makeTuples(self, key)
		%!!! compute missing fields for key here
			 self.insert(key)
		end
	end

end