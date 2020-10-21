%{
# brain area membership of cells
-> fuse.ScanSetUnit
-> map.RetMap
---
sign                        : double                        # vertical retinotopic angle
%}


classdef UnitSign <  dj.Computed
    
    properties
        keySource = map.RetMap*fuse.ScanDone & map.SignField
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            % get scan info
            setup = fetch1(experiment.Scan * experiment.Session & key,'rig');
            field_keys = fetch(fuse.ScanSet*map.RetMap*proj(anatomy.RefMap) & key);
            
            % process cells from each field
            for field_key = field_keys'
                
                % build image with area masks
                ret_key = [];
                ret_key.animal_id = field_key.animal_id;
                ret_key.ret_idx = field_key.ret_idx;
                SIGNMAP = fetch1(map.SignField & field_key,'sign_map');
                
                % fetch cell coordinates
                if strcmp(setup,'2P4')
                    [px,wt,keys] = fetchn(meso.SegmentationMask*meso.ScanSetUnit & field_key,'pixels','weights');
                    keys = rmfield(keys,{'field','mask_id','channel'});
                else
                    [px,wt,keys] = fetchn(reso.SegmentationMask*reso.ScanSetUnit & key,'pixels','weights');
                end
                [keys.ret_idx] = deal(key.ret_idx);
                
                % insert each cell
                for imask = 1:length(keys)
                    % get mask position
                    
                    tuple = keys(imask);
                    idx= px{imask}<=numel(SIGNMAP);
                    tuple.sign =  sum(SIGNMAP(px{imask}(idx)).*wt{imask}(idx))/sum(wt{imask}(idx));
                    
                    % insert
                    self.insert(tuple);
                end
            end
            
        end
    end
    
end