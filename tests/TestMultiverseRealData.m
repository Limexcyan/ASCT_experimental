classdef TestMultiverseRealData < matlab.unittest.TestCase
    % Tests the setup-driven real-data scheduler without running FieldTrip.
    methods (TestClassSetup)
        function addMultiverse(testCase)
            root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'multiverse'));
            testCase.addTeardown(@()rmpath(fullfile(root,'multiverse')));
        end
    end
    methods (Test)
        function step10TwoAlternatives(testCase)
            mv=baseOptions();
            mv.factors.con.varNorm=[0 1];
            specs=asct_multiverse_realdata_grid(mv);
            testCase.verifyEqual(numel(specs),2);
            testCase.verifyEqual([specs.startStep],[10 10]);
            testCase.verifyEqual(specs(1).changes.con.varNorm,0);
            testCase.verifyEqual(specs(2).changes.con.varNorm,1);
        end
        function highCostChangeRequiresEarlierStages(testCase)
            mv=baseOptions();
            mv.factors.loc.depthWeight=[0 0.5];
            specs=asct_multiverse_realdata_grid(mv);
            testCase.verifyEqual(specs(1).startStep,8);
            mv.factors.filter.HPfreq=[1 8];
            specs=asct_multiverse_realdata_grid(mv);
            testCase.verifyEqual(specs(1).startStep,0);
            mv=baseOptions();
            mv.factors.con.decimate=[1 2];
            specs=asct_multiverse_realdata_grid(mv);
            testCase.verifyEqual(specs(1).startStep,9);
        end
        function rejectsRunExplosion(testCase)
            mv=baseOptions();
            mv.maxRuns=2;
            mv.factors.con.varNorm=[0 1];
            mv.factors.con.mvarOrd=[2 5];
            testCase.verifyError(@()asct_multiverse_realdata_grid(mv), ...
                'ASCT:RealMultiverse:TooManyRuns');
        end
        function rejectsUnknownFactor(testCase)
            mv=baseOptions();
            mv.factors.con.someParameter=[1 2];
            testCase.verifyError(@()asct_multiverse_realdata_grid(mv), ...
                'ASCT:RealMultiverse:UnsupportedFactor');
        end
        function dryRunUsesBaselineROISignals(testCase)
            [p,folder]=fixture(testCase);
            mv=baseOptions();
            mv.factors.con.varNorm=[0 1];
            results=asct_multiverse_realdata(p,mv);
            testCase.verifyEqual({results.status},{'planned','planned'});
            testCase.verifyEqual([results.startStep],[10 10]);
            testCase.verifyTrue(isfile(fullfile(folder,'experiment__multiverse','realdata_manifest.csv')));
            testCase.verifyFalse(isfolder(fullfile(folder,'experiment__mv_0001')));
            specs=asct_multiverse_realdata_grid(mv);
            r=asct_multiverse_realdata_prepare(p,mv,specs(1));
            testCase.verifyEqual(r.rc.sigroiName,'previous');
            testCase.verifyEqual(r.rc.load,10);
            testCase.verifyEqual(r.rc.stop,10);
        end
        function dryRunLocalizationReusesICA2(testCase)
            [p,folder]=fixture(testCase);
            mkdir(fullfile(folder,'previous','6_ICA2'));
            mv=baseOptions();
            mv.factors.loc.depthWeight=[0 0.5];
            specs=asct_multiverse_realdata_grid(mv);
            r=asct_multiverse_realdata_prepare(p,mv,specs(1));
            testCase.verifyEqual(r.rc.ica2Name,'previous');
            testCase.verifyFalse(isfield(r.rc,'iclocName'));
            testCase.verifyEqual(r.rc.load,8);
        end
        function realModeWithStubRunner(testCase)
            [p,folder]=fixture(testCase);
            mv=baseOptions();
            mv.factors.con.varNorm=[0 1];
            mv.dryRun=false;
            results=asct_multiverse_realdata(p,mv,@(~,~,~)struct('stub',true));
            testCase.verifyTrue(all(strcmp({results.status},'passed')));
            testCase.verifyTrue(isfile(fullfile(folder,'experiment__mv_0001','multiverse_setup.mat')));
            testCase.verifyTrue(isfile(fullfile(folder,'experiment__multiverse','realdata_results.mat')));
        end
        function missingBaselineFailsBeforeExecution(testCase)
            [p,folder]=fixture(testCase);
            rmdir(fullfile(folder,'previous','7_SOURCEACT'),'s');
            mv=baseOptions();
            mv.factors.con.varNorm=[0 1];
            testCase.verifyError(@()asct_multiverse_realdata(p,mv), ...
                'ASCT:RealMultiverse:MissingInput');
        end
    end
end

function mv=baseOptions()
mv=struct();
mv.sourceAnalysis='previous';
mv.dryRun=true;
mv.maxRuns=4;
mv.factors=struct();
end

function [p,folder]=fixture(testCase)
folder=tempname;
mkdir(folder);
testCase.addTeardown(@()rmdir(folder,'s'));
mkdir(fullfile(folder,'previous','7_SOURCEACT'));
p.rc=struct('expFolder',folder,'analysisName','experiment','dataRawFolder','0_raw');
p.chan=struct(); p.filter=struct(); p.seg=struct(); p.ar=struct();
p.ica=struct(); p.loc=struct('method','mne','norm','cov');
p.con=struct('mvarOrd',2,'lc',1,'unc',0);
p.design=struct();
end
