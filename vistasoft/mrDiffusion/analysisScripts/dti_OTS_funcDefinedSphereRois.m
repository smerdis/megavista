% This script is based on 'dti_OTSfiberprocessing'. It will load several subjects' dt6 files, load ROTS/LOTS ROIs,
% grow a 30mm sphere in center of the functionally defined ROI, track
% fibers, restrict to those fibers that have endpoints in an 8mm sphere with the
% same center, and save these fibers.

% This sets the base directory, checks for LOTS/ROTS.mat files, and creates
% a list of appropriate subjects
baseDir = 'Y:\data\reading_longitude\dti'; %path to subjects' dti data on harddrive
cd(baseDir);
d = dir('*0*'); % lists all directories 
f = {d.name};

% Parameters
radius = 30; % for sphere
smallr = 8; % for endpoints
opts.stepSizeMm = 1; % all opts are for tracking
opts.faThresh = 0.2;
opts.lengthThreshMm = 20;
opts.angleThresh = 30;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [0.334 0.667];
distanceFromRoi = 0.87; % intersection parameter, minimum value because already dilated

%change to the appropriate directory, you call a variable
%as if it were a parameter in a function and put the string in parentheses
% cd(baseDir); 
for(ii=1:length(f))
    fname = fullfile(baseDir, f{ii}, [f{ii} '_dt6.mat']); %concatenates stuff in braket into one string, commas add slashes to create a valid path
    disp(['Processing ' fname '...']); %displays a string on the screen
    dt = load(fname); % this will load the dt6 file; you can doublechecheck by typing 'dt.dt6' and it will be a 3-D matrix + 1 more with 6 in it for the six diffusion directions

    % Apply the brain mask if it exists. (Older dt6 files with no dtBrainMask field are implicitly masked.)
    % Code suggested by Bob so fibers are not tracked outside the brain
    % (8/23/2006)
    if(isfield(dt,'dtBrainMask'))
        dt.dt6(repmat(~dt.dtBrainMask, [1,1,1,6])) = 0;
    end

    %Checks for OTSproject directories and creates them if they do not exist
    roiName = {'ROTS', 'LOTS'}; %curly brackets are good for lists of strings ROI name list
    roiPath = fullfile(fileparts(fname), 'ROIs', 'OTSproject');
    if ~exist(roiPath,'dir')
        mkdir(fullfile(fileparts(fname), 'ROIs', 'OTSproject'));
    end
    fiberPath = fullfile(fileparts(fname), 'fibers', 'OTSproject');
    if ~exist(fiberPath,'dir')
        mkdir(fullfile(fileparts(fname), 'fibers', 'OTSproject')); 
    end

    % If ROI exists, load it, and analyze it. 
    for (jj=1:length(roiName))
        roiFileName = fullfile(roiPath,[roiName{jj} '.mat']);
        if exist(roiFileName,'file')
            roi = dtiReadRoi(roiFileName); % this should not have empty 'coords' field
            
            % FINDS CENTER OF FUNCTIONAL ROI AND BUILDS A SMALL 8MM SPHERE ROI
            smallName = [roiName{jj} '_sphere' num2str(smallr, '%01d')];
            smallSphere = dtiNewRoi(smallName, 'r');
            centerCoord = round(mean(roi.coords,1)*10)/10; % finds center of ROI
            smallSphere.coords = dtiBuildSphereCoords(centerCoord, smallr); % builds sphere of radius 30
            dtiWriteRoi(smallSphere, fullfile(roiPath, [smallSphere.name '.mat'])); % save sphere ROI
                     
            % FINDS CENTER OF FUNCTIONAL ROI AND BUILDS A 30MM SPHERE ROI
            sphereName = [roiName{jj} '_sphere' num2str(radius, '%02d')];
            bigSphere = dtiNewRoi(sphereName, 'r'); %sphereName is in the .name field, see dtiNewRoi for more details
            centerCoord = round(mean(roi.coords,1)*10)/10; % finds center of ROI
            bigSphere.coords = dtiBuildSphereCoords(centerCoord, radius); % builds sphere of radius 30
            dtiWriteRoi(bigSphere, fullfile(roiPath, [bigSphere.name '.mat'])); % save sphere ROI
            
            % TRACKS FIBERS FROM 30MM SPHERE
            fgSphere = dtiFiberTrack(dt.dt6, bigSphere.coords, dt.mmPerVox, dt.xformToAcPc, [bigSphere.name '_FG'],opts);            
            dtiWriteFiberGroup(fgSphere, fullfile(fiberPath, [fgSphere.name '.mat'])); % saves fiber group
            
            %intersect BY ENDPTS fiber group with small sphere roi
            fgRestricted = dtiIntersectFibersWithRoi(0, {'and','endpoints'}, distanceFromRoi, smallSphere, fgSphere, inv(dt.xformToAcPc));
            fgRestricted.name = smallSphere.name; % save the fiber group
            dtiWriteFiberGroup(fgRestricted, fullfile(fiberPath, [fgRestricted.name '.mat']));
        end
        clear smallSphere bigSphere fgSphere
    end
end