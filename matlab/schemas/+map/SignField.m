%{
# SignMap for each field
-> experiment.Scan
-> shared.Field
---
-> map.RetMap
sign_map                 : mediumblob      # sign map of the retinotopy
%}

classdef SignField < dj.Manual
    methods
        function extractMasks(obj, keyI)
            
            % fetch all area masks
            keyI.ret_idx = fetch1(map.RetMap & keyI,'ret_idx');
            
            %map_keys = fetch(map.SignField & (anatomy.RefMap & (proj(anatomy.RefMap) & (anatomy.FieldCoordinates & keyI))));
            [sign_map, ret_idx] = fetch1(map.SignMap & keyI, 'sign_map', 'ret_idx');
            
            % loop through all fields
            for field_key = fetch(anatomy.FieldCoordinates & keyI)'
                
                % find corresponding mask area
                fmask = filterMask(anatomy.FieldCoordinates & field_key, sign_map);
                
                % insert if overlap exists
                if ~all(~fmask(:))
                    tuple = rmfield(field_key,'ref_idx');
                    if ~exists(obj & tuple)
                        tuple.sign_map = fmask;
                        tuple.ret_idx = keyI.ret_idx;
                        insert(obj,tuple)
                    end
                end
            end
        end
        
        function [fmasks, fields] = splitContiguousMask(~, key, ref_mask)
            
            % fetch images
            if strcmp(fetch1(experiment.Session & key,'rig'),'2P4')
                [x_pos, y_pos, fieldWidths, fieldHeights, fieldWidthsInMicrons,keys] = ...
                    fetchn(meso.ScanInfoField * meso.SummaryImagesAverage & key,...
                    'x','y','px_width','px_height','um_width');
                
                % calculate initial scale
                pxpitch = mean(fieldWidths.\fieldWidthsInMicrons);
                
                % start indexes
                XX = (x_pos - min(x_pos))/pxpitch;
                YY = (y_pos - min(y_pos))/pxpitch;
                
                % deconstruct the big field of view
                for ifield = 1:length(x_pos)
                    fields(ifield) = keys(ifield).field;
                    fmasks{ifield} = ref_mask(YY(ifield)+1:fieldHeights(ifield)+YY(ifield),...
                        XX(ifield)+1:fieldWidths(ifield)+XX(ifield));
                end
            else % for all other scans there is no need to split the mask
                keys = fetch(meso.ScanInfoField * reso.SummaryImagesAverage & key);
                for ikey = 1:length(keys)
                    fields(ikey) = keys(ikey).field;
                    fmasks{ikey} = ref_mask;
                end
            end
        end
        
        function [area_map, keys, background] = getContiguousMask(obj, key)
            
            % fetch masks & keys
            [masks, keys] = fetchn(obj & key,'sign_map');
           
                % get information from the scans depending on the setup
            if  (strcmp(fetch1(experiment.Session & key,'rig'),'2P4'))
                [x_pos, y_pos, fieldWidths, fieldHeights, fieldWidthsInMicrons, masks, avg_image] = ...
                    fetchn(obj * meso.ScanInfoField * meso.SummaryImagesCorrelation & key,...
                    'x','y','px_width','px_height','um_width','sign_map','correlation_image');
                
                % calculate initial scale
                pxpitch = mean(fieldWidths.\fieldWidthsInMicrons);
                
                % construct a big field of view
                x_pos = (x_pos - min(x_pos))/pxpitch;
                y_pos = (y_pos - min(y_pos))/pxpitch;
                area_map = zeros(ceil(max(y_pos+fieldHeights)),ceil(max(x_pos+fieldWidths)));
                background = zeros(size(area_map));
                for islice =length(masks):-1:1
                    mask = double(masks{islice});
                    y_idx = ceil(y_pos(islice)+1):ceil(y_pos(islice))+size(mask,1);
                    x_idx = ceil(x_pos(islice)+1):ceil(x_pos(islice))+size(mask,2);
                    back = area_map(y_idx, x_idx);
                    area_map(y_idx, x_idx) = max(cat(3,mask,back),[],3);
                    background(y_idx, x_idx) = avg_image{islice}(1:size(mask,1),1:size(mask,2));
                end
                
            elseif ~strcmp(fetch1(experiment.Session & key,'rig'),'2P4')
                
                area_map = masks{1};
                background= zeros(size(masks{1}));
                bck = fetch1(obj * reso.SummaryImagesCorrelation & key & 'field=1' & 'channel = 1','correlation_image');
                background = bck(1:size(background,1),1:size(background,2));
            end
        end
        
        function varargout = plot(obj, varargin)
            params.back_idx = [];
            params.bcontrast = 0.4;
            params.contrast = 1;
            params.exp = 1;
            params.sat = 1;
            params.colors = [];
            params.linewidth = 1;
            params.fill = 1;
            params.restrict = [];
            params.red = 1;
            params.fontsize = 12;
            params.fontcolor = [0.4 0 0];
            params.vcontrast = 1;
            params.limits = 0;
            
            params = ne7.mat.getParams(params,varargin);

            % get masks
            [area_map, keys, mask_background] = getContiguousMask(obj,fetch(obj));
           
            
            % get maps
            if exists(map.RetMap & (map.RetMapScan &  obj))
                background = getBackground(map.RetMap & (map.RetMapScan &  obj));
                
                % if FieldCoordinates exists add it to the background
                if exists(anatomy.FieldCoordinates & proj(anatomy.RefMap & obj) & params.restrict)
                    background = cat(4,background,plot(anatomy.FieldCoordinates & ...
                        proj(anatomy.RefMap & obj) & params.restrict,params));
                    if isempty(params.back_idx)
                        params.back_idx = size(background,4);
                    end
                end
            else
                background = mask_background;
            end
            
            % adjust background contrast
            background = ne7.mat.normalize(abs(background.^ params.bcontrast));
            
            % merge masks with background
            figure
            sat = background(:,:,1,1)*params.sat;
            sat(area_map==0) = 0;
            back = background(:,:,1,1);
            if params.limits
                mn = prctile(back(:),1);
                mx = prctile(back(:),99);
                back(back<mn) = mn;
                back(back>mx) = mx;
                back = normalize(back);
            end
           
            if params.back_idx
                im = hsv2rgb(cat(3,ne7.mat.normalize(area_map),sat,back));
                image((im));
            else
                imagesc(area_map)
                colors = cbrewer('div','RdBu',100);
                colormap(colors)
            end
            hold on
            axis image;
            key = fetch(proj(experiment.Scan) & obj);
            set(gcf,'name',sprintf('Animal:%d Session:%d Scan:%d',key.animal_id,key.session,key.scan_idx))
          
            if nargout>0
                varargout{1} = im;
                if nargout>1
                    varargout{2} = area_map;
                    if nargout>2
                        varargout{3} = areas;
                    end
                end
            end
            
        end
    end
end