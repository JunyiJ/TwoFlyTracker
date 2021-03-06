
% This script is to perform tracking on flies in courtship.
% Run AnnotateVideo.m first before runing this.


% Select annotated .mat files
allfiles_ori = uigetfile('*.mat','MultiSelect','on');

if ~ischar(allfiles_ori) %Multiple files, class(allfiles_ori) = cell
    allfiles = cell2struct(allfiles_ori,'name');
else %Single file, class(allfiles_ori) = char
    allfiles = struct; 
    allfiles(1).name = allfiles_ori;
end

for fi =1:length(allfiles)
    
    annotation_file = allfiles(fi).name;
    load(annotation_file);
    disp(annotation_file),disp('Loaded');
    movie = VideoReader(moviefile);
    
    nframes = get(movie,'NumberOfFrames');
    
    % Prepare data matrixes-------------Start----------------------------
    posx = NaN(2,nframes);
    posy = NaN(2,nframes);
   
    orientation = NaN(2,nframes);
    area = NaN(2,nframes);
    MajorAxis = NaN(2,nframes);
    MinorAxis = NaN(2,nframes); 
    WE = NaN(2,nframes);
    
    collisions = NaN(1,nframes);
    min_body_dist_s = NaN(1,nframes);
    fly_apart_error_s = NaN(1,nframes);
    
    initial_wing_area = [];
    initial_body_area = [];
    initial_body_MajorAxisLength = [];
    initial_body_MinorAxisLength = [];
    % Prepare data matrixes-------------End--------------------------------
    
    

    %Get background.
    background = get_background(annotation_file, moviefile, Channel);
    
    %Get Thresh-------------Start----------------------------
    ff = read(movie,StartTracking);
    ff = ff (:,:,Channel);
    mask_ROI = ROI2mask(ff,ROIs);
    mask_thresh_ROI = ROI2mask(ff,thresh_ROIs);
    ff = ff.*mask_ROI;
    flies = background - ff;
    flies_for_thresh = flies.*mask_thresh_ROI;
    
    %Two thresholds are generated. One for body only. The other for
    %body+wings.
    thresh = multithresh (flies_for_thresh,2); 
    %Get Thresh-------------End----------------------------
    
    fprintf('The thresholds for %s are %d and %d.\n'...
        ,moviefile, thresh(1),thresh(2))
    
    
    for frame = StartTracking:StopTracking
        
        [rp_body, rp_with_wing, fly_body, fly_with_wing] = ...
            get_flies(frame, background, Channel, movie, thresh, mask_ROI);
        
        %get some info from first frame
        if frame == StartTracking,
            initial_wing_area = [rp_with_wing.Area];
            initial_body_area = [rp_body.Area];
            initial_body_MajorAxisLength = [rp_body.MajorAxisLength];
            initial_body_MinorAxisLength = [rp_body.MinorAxisLength];
            tic
        end
        


        [fly_body, fly_with_wing, fly_apart_error, collision, min_body_dist] = ...
            fly_apart(rp_body, rp_with_wing, fly_body, fly_with_wing, initial_body_area, initial_wing_area, initial_body_MajorAxisLength, frame);
        
        [WE_score, WE_is] = ...
            WingExtension(fly_apart_error, fly_body, fly_with_wing, initial_body_area, initial_wing_area, initial_body_MajorAxisLength, initial_body_MinorAxisLength, ROIs, frame);
        
        [posx, posy, orientation, area, MajorAxis, MinorAxis, WE, collisions, min_body_dist_s, fly_apart_error_s] =...
            assign_flies(fly_apart_error, fly_apart_error_s, fly_body, fly_with_wing, frame, StartTracking, posx, posy, orientation,area, MajorAxis, MinorAxis, WE, WE_is, collisions, collision, min_body_dist_s, min_body_dist);
    
        % Every 1000 frames, disp fps & save to file
        if rem(frame,1000)==0
            t = toc;
            fps = 1000/t;
            fprintf('frame:%d.  fps: %f.\n',frame,fps);
            save(strcat(annotation_file(1:end-8),'trck','.','mat'),'posx','posy','orientation','area','MajorAxis','MinorAxis','WE','collisions','min_body_dist_s','fly_apart_error_s','StartTracking','StopTracking','moviefile','ROIs','thresh_ROIs','Channel')
            tic
        end
        
    end
    save(strcat(annotation_file(1:end-8),'trck','.','mat'),'posx','posy','orientation','area','MajorAxis','MinorAxis','WE','collisions','min_body_dist_s','fly_apart_error_s','StartTracking','StopTracking','moviefile','ROIs','thresh_ROIs','Channel')

    clearvars -except allfiles fi;
end

%Finshed, send a email to myself
send_email('Core Finished','')

