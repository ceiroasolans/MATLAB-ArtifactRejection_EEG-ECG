

%% This script applies EEG and ECG artifact epochs to hypno file
    %Inputs: 
        %EEG Artifacts: P#_artifact_epoch_primary.csv
        %ECG Artifacts: P#_ECG_Artifacts.csv
        %Hypno file: P#_hypno.txt
    %Output: 
        %P#__CleanHypno.txt 
        
        
%% First, we add the server directories we need for the EEG & ECG artifact data
addpath(genpath('/serverdir'))
addpath(genpath('/serverdir'))
    
all_subs = {'xx'}; %specify participant numbers of interest here

eeg_dir = 'EEG_Artifacts_dir'; 
ecg_dir = 'ECG_Artifacts_dir';
out_dir = 'output_directory_where_we_want_the_output_file';


%% Load in the data
for s = [1:length(all_subs)]

    % Pull data from individual participant files 
    subj = all_subs{s};
    subj_eeg_dir = [eeg_dir '/' subj];
    subj_ecg_dir = [ecg_dir '/' subj];
    subj_out_dir = [out_dir '/'];
    
    %Read individual participant files
    disp(['***************************** Processing: ', subj, ' ************************************']);
    
    excel = readmatrix([subj_eeg_dir '/' subj '_EEG_Artifacts.csv']);
    text = readmatrix([subj_eeg_dir subj '.txt']);               
    ecg_artifact = readmatrix([subj_ecg_dir subj '_ECG_Artifacts.csv']);
    
    excelNum = extractBefore(excel,"_artifact_epoch.csv");%take P# from csv & txt files
    textNum = extractBefore(text,"_hypno.txt");
    
    %Transform to hypno time-scale and import hypno 
    if excelNum == textNum                     %if-statement to make sure only same-P files are being used
        EEG_Artifact = floor (excel/6);            % make representative of 30-sec epoch
        EEG_Artifact(EEG_Artifact < 1 ) = 1;           % first epoch allowed is 1 (not 0)
       
        delimiterIn = ' ';
        Hypno = importdata(txt,delimiterIn);    %import hypno
        
   %Make adjustments to hypno file
    
  for i = 1:length(Hypno)                    %Recode Stages to numerical 
   if Hypno{i} == '?'
       stages(i)= 7;
   elseif Hypno{i} == 'W'
       stages(i)= 0;
   elseif Hypno{i} == 'N1'
       stages(i)= 1;
   elseif Hypno{i} == 'N2'
       stages(i)= 2;
   elseif Hypno{i} == 'N3'
       stages(i)= 3;
   elseif Hypno{i} == 'R'
       stages(i)= 5;
   else
       stages(i)=-1;
   end
  end
    %stages = stages';   
    
    
    
%% EEG Artifact Rejection

%Find the first value that is not "?" or "W" in the hypno file (=asleep)
first_value = find(stages==not(7));          
first_value = find(stages==not(0));
first_value=first_value(1,:);                %Return first value in this list

%Erase non-sleep stages in hypnogram (artifact files don't have it) Match Hypnogram with artifact epoch file (when P falls asleep)
stages(1:first_value) = [];        

% APPLY EEG Artifact
stages(EEG_Artifact) = "4";   % Change stage# in epochs with ARTIFACT to "4"                 

 %Reshape hypno to original hypno size
A = ones(1, position)*7;                     
stages = [A stages];



%% ECG Artifact Rejection

%Make data adjustments
ECG_Artifacts = readmatrix(ecg_artifact);      %load ECG artifact table
 ECG_Artifacts = ECG_Artifacts / 30;          %transform to Artifact_Rejection timescale
 Beg = ECG_Artifacts(:,1);                    %reshape data
 End = ECG_Artifacts(:,2);
 ECG_Artifacts = [Beg; End];
 ECG_Artifacts = sort(ECG_Artifacts);           
 ECG_Artifacts = floor(ECG_Artifacts)';
 
 
 %Apply ECG Artifact
 stages(ECG_Artifacts) = "4";      %Change stage# in ECG artifact epochs to "4"

 
 last = ECG_Artifacts(end);                   %overwrite hypno with 7's after ECG signal becomes messy
 ecg_wake = last:+1:length(stages);                 
 stages(ecg_wake) = "7";

 
 %% Save data

save(stages,[subj_eeg_dir subj 'CleanHypno_.mat']);


    else
        break
    end
end

   