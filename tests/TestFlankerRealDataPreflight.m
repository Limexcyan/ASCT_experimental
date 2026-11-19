classdef TestFlankerRealDataPreflight < matlab.unittest.TestCase
    % Checks real-data input validation using fake, lightweight ROI MAT files.
    methods (TestClassSetup)
        function installPaths(testCase)
            root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'multiverse'));
            testCase.addTeardown(@()rmpath(fullfile(root,'multiverse')));
        end
    end
    methods (Test)
        function acceptsPairedROIs(testCase)
            [p,mv]=makeFixture(testCase);
            summary=asct_multiverse_flanker_preflight(p,mv);
            testCase.verifyEqual(numel(summary),2);
            testCase.verifyEqual([summary.selected],[2 2]);
            testCase.verifyEqual(summary(1).ids,{'01','02'});
        end
        function rejectsUnpairedSubjects(testCase)
            [p,mv,folder]=makeFixture(testCase);
            d=fullfile(folder,'ana1','7_SOURCEACT','DC2','lc');
            movefile(fullfile(d,'02_A_sigroi_lc.mat'), ...
                fullfile(d,'03_A_sigroi_lc.mat'));
            testCase.verifyError(@()asct_multiverse_flanker_preflight(p,mv), ...
                'ASCT:Flanker:UnpairedSubjects');
        end
        function rejectsTooFewDatasets(testCase)
            [p,mv,folder]=makeFixture(testCase);
            delete(fullfile(folder,'ana1','7_SOURCEACT','DC2','lc', ...
                '02_A_sigroi_lc.mat'));
            testCase.verifyError(@()asct_multiverse_flanker_preflight(p,mv), ...
                'ASCT:Flanker:TooFewDatasets');
        end
        function rejectsRepeatedSubjectIdsForPairedStats(testCase)
            [p,mv,folder]=makeFixture(testCase);
            for dc=1:2
                d=fullfile(folder,'ana1','7_SOURCEACT',sprintf('DC%d',dc),'lc');
                movefile(fullfile(d,'02_A_sigroi_lc.mat'), ...
                    fullfile(d,'01_B_sigroi_lc.mat'));
            end
            testCase.verifyError(@()asct_multiverse_flanker_preflight(p,mv), ...
                'ASCT:Flanker:DuplicateIDs');
        end
    end
end

function [p,mv,folder]=makeFixture(testCase)
folder=tempname;
mkdir(folder);
testCase.addTeardown(@()rmdir(folder,'s'));
p.rc=struct('expFolder',folder,'analysisName','single');
p.con=struct('lc',1,'unc',0,'testType','within', ...
    'contrast2test',{{[1 2]}});
p.design.idPosStart=1;
p.design.idPosEnd=2;
p.design.DC(1).name='inco';
p.design.DC(2).name='cong';
p.begId=1;
p.endId=2;
mv=struct('sourceAnalysis','ana1','runStatistics',true);
for dc=1:2
    dest=fullfile(folder,'ana1','7_SOURCEACT',sprintf('DC%d',dc),'lc');
    mkdir(dest);
    for i=1:2
        data_sigroi=struct('signal',ones(5,10),'trialen',10); %#ok<NASGU>
        save(fullfile(dest,sprintf('%02d_A_sigroi_lc.mat',i)), ...
            'data_sigroi');
    end
end
end
