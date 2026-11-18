classdef TestMultiverse < matlab.unittest.TestCase
    % End-to-end ORACLE-source benchmark and ASCT field mapping contract.
    % Real FieldTrip localization and external multar runtime require setup.
    methods (TestClassSetup)
        function addMultiverse(testCase)
            root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'multiverse'),fullfile(root,'external','mmultar'));
            testCase.addTeardown(@() rmpath(fullfile(root,'multiverse'),fullfile(root,'external','mmultar')));
        end
    end
    methods (Test)
        function reproducibleGridAndScenarioPairing(testCase)
            st=asct_multiverse_defaults();
            st.factors=struct('nSources',3,'distanceCm',1.5, ...
                'nInteractions',1,'strength',0.4,'lag',1,'snrDb',15, ...
                'evokedAmplitude',0,'bandMode',{{'wide'}}, ...
                'locNorm',{{'lambda','cov'}}, 'lambda',0.1, ...
                'depthWeight',0, 'locMethod',{{'mne'}},'nROIs',5, ...
                'orderMode',{{'fixed'}},'fixedOrder',1,'varNorm',1,'removeERP',0);
            st.maxRuns=2;
            before=rng;
            g1=asct_multiverse_grid(st);
            after=rng;
            testCase.verifyEqual(before,after);
            g2=asct_multiverse_grid(st);
            testCase.verifyEqual(g1,g2);
            testCase.verifyEqual(numel(g1),2);
            testCase.verifyEqual(g1(1).simSeed,g1(2).simSeed);
            testCase.verifyNotEqual(g1(1).locNorm,g1(2).locNorm);
        end
        function simulationReproducesAndRespectsGeometry(testCase)
            st=asct_multiverse_defaults();
            st.simulation.nSamples=96;
            st.simulation.nTrials=4;
            cfg=asct_multiverse_grid(st);
            c=cfg(1);
            c.nSources=4; c.nInteractions=2; c.distanceCm=1.5;
            c.lag=2; c.simSeed=77;
            sim1=asct_multiverse_simulate(c,st.simulation);
            sim2=asct_multiverse_simulate(c,st.simulation);
            testCase.verifyEqual(sim1.sensors,sim2.sensors);
            testCase.verifySize(sim1.sensors,[st.simulation.nSensors 96 4]);
            testCase.verifyEqual(nnz(sim1.truth),2);
            testCase.verifyTrue(sim1.truth(2,1) && sim1.truth(3,2));
            testCase.verifyEqual(diff(sim1.positionsCm(:,1)),1.5*ones(3,1));
            testCase.verifyError(@()asct_multiverse_simulate(localBad(c),st.simulation), ...
                'ASCT:InvalidInteractions');
        end
        function evokedMeanRemovalDoesNotDivide(testCase)
            t=(1:64);
            x=zeros(2,64,3);
            for k=1:3
                x(:,:,k)=[t;2*t]+k*ones(2,64);
            end
            y=asct_remove_erp(x);
            testCase.verifyLessThan(max(abs(mean(y,3)),[],'all'),1e-12);
            y2=asct_remove_erp(reshape(x,2,[]),64);
            testCase.verifyEqual(y2,reshape(y,2,[]),'AbsTol',1e-12);
            testCase.verifyError(@()asct_remove_erp(randn(2,10),7),'ASCT:InvalidTrialLength');
        end
        function mvarDirectionAndModelOrder(testCase)
            st=asct_multiverse_defaults();
            st.simulation.nSamples=1024;
            st.simulation.nTrials=20;
            c=asct_multiverse_grid(st); c=c(1);
            c.nSources=3; c.nInteractions=1; c.lag=2;
            c.strength=0.75; c.snrDb=100; c.evokedAmplitude=0;
            c.simSeed=12;
            s=asct_multiverse_simulate(c,st.simulation);
            [order,criterion]=asct_mvar_aic(s.trueSources,5);
            testCase.verifyGreaterThanOrEqual(order,2);
            testCase.verifyLessThanOrEqual(order,5);
            testCase.verifyLessThan(criterion(2),criterion(1));
            testCase.verifyEqual(numel(criterion),5);
            A=asct_mvar_fit(s.trueSources,order);
            d=asct_mvar_dtf(A,s.fs,linspace(1,30,31));
            testCase.verifyGreaterThan(mean(squeeze(d(2,1,:))),mean(squeeze(d(1,2,:))));
            testCase.verifyLessThan(max(abs(sum(d.^2,2)-1),[],'all'),1e-10);
            score=asct_multiverse_score(d,s.truth,0.15);
            testCase.verifyGreaterThan(score.f1,0.8);
            testCase.verifyLessThanOrEqual(score.f1,1);
        end
        function parametersReachProductionFields(testCase)
            st=asct_multiverse_defaults();
            c=asct_multiverse_grid(st); c=c(1);
            c.nROIs=5; c.bandMode='narrow'; c.locNorm='cov';
            c.depthWeight=0.5; c.orderMode='aic'; c.varNorm=0; c.removeERP=1;
            p=makeSetup();
            p=asct_multiverse_apply(p,c,st);
            testCase.verifyEqual(p.filter.HPfreq,8);
            testCase.verifyEqual(p.filter.LPfreq,12);
            testCase.verifyEqual(p.loc.norm,'cov');
            testCase.verifyEqual(p.loc.depthWeight,0.5);
            testCase.verifyEqual(p.con.varNorm,0);
            testCase.verifyEqual(p.con.mvarOrd,0);
            testCase.verifyEqual(p.con.orderSelection,'aic');
            testCase.verifyTrue(p.con.removeERP);
            testCase.verifyEqual(p.con.chanSel,'1-5');
            testCase.verifyEqual(p.rc.load,0);
            testCase.verifyEqual(p.rc.stop,10);
            testCase.verifyTrue(contains(p.rc.analysisName,c.id));
            c.locMethod='lcmv';
            testCase.verifyError(@()asct_multiverse_apply(makeSetup(),c,st), ...
                'ASCT:UnsupportedLocalization');
        end
        function preparationUsesHeadlessAICAndERP(testCase)
            st=asct_multiverse_defaults();
            st.simulation.nSamples=512; st.simulation.nTrials=8;
            c=asct_multiverse_grid(st); c=c(1);
            c.nSources=3; c.nInteractions=1; c.lag=1; c.simSeed=44;
            s=asct_multiverse_simulate(c,st.simulation);
            mv=struct('recl',512,'chansel','1-3','removeERP',true, ...
                'orderSelection','aic','maxMvarOrder',4, ...
                'norm0',0,'norm1',0,'userange',0);
            [out,mv]=asct_multiverse_prepare_mltin(reshape(s.trueSources,3,[]),mv);
            testCase.verifySize(out,[3 512*8]);
            testCase.verifyGreaterThanOrEqual(mv.pord,1);
            testCase.verifyLessThanOrEqual(mv.pord,4);
            testCase.verifyLessThan(max(abs(mean(reshape(out,3,512,8),3)),[],'all'),1e-10);
        end
        function referenceBenchmarkBootstrapAndCallbackRunner(testCase)
            st=asct_multiverse_defaults();
            st.maxRuns=2;
            st.simulation.nSamples=128;
            st.simulation.nTrials=6;
            c=asct_multiverse_grid(st); c=c(1);
            c.nSources=3; c.nInteractions=1; c.nROIs=5;
            c.lag=1; c.fixedOrder=1; c.orderMode='fixed';
            m=asct_multiverse_source_benchmark(c,st,4);
            testCase.verifyTrue(m.oracleSourceBenchmark);
            testCase.verifyGreaterThanOrEqual(m.f1,0);
            testCase.verifyLessThanOrEqual(m.bootstrapF1CI(1),m.bootstrapF1CI(2));
            output=tempname;
            cleaner=onCleanup(@()removeFolder(output)); %#ok<NASGU>
            result=asct_multiverse_run(st,@(~,~)makeSetup(),output, ...
                @(p,~,~)struct('name',p.rc.analysisName));
            testCase.verifyEqual({result.status}',{'passed';'passed'});
            testCase.verifyTrue(isfile(fullfile(output,'multiverse_results.mat')));
            testCase.verifyTrue(isfile(fullfile(output,'multiverse_manifest.csv')));
            testCase.verifyNotEqual(result(1).output.name,result(2).output.name);
        end
    end
end

function c=localBad(c)
c.nInteractions=c.nSources;
end
function p=makeSetup()
p.rc=struct('analysisName','case1');
p.chan=struct();p.filter=struct();p.seg=struct();p.ar=struct();
p.ica=struct();p.loc=struct('noiseLev',0.1,'ROI',repmat(struct('name','roi'),1,12));
p.con=struct();p.design=struct();
end
function removeFolder(path)
if isfolder(path), rmdir(path,'s'); end
end
