classdef TestMultiverseM6 < matlab.unittest.TestCase
    % Source-causal truth, geometry-dependent sensors, and independent cases.
    methods (TestClassSetup)
        function paths(tc)
            root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'multiverse'));
            tc.addTeardown(@()rmpath(fullfile(root,'multiverse')));
        end
    end
    methods (Test)
        function causalTruthAndDeterminism(tc)
            cfg=localConfig();opts=localOptions();
            state=rng;
            a=asct_m6_generate(cfg,opts);
            b=asct_m6_generate(cfg,opts);
            tc.verifyEqual(a.trueA,b.trueA);
            tc.verifyEqual(a.sensors,b.sensors);
            tc.verifyEqual(rng,state);
            tc.verifyEqual(nnz(a.truth),2);
            tc.verifySize(a.trueA,[3 3 2]);
            tc.verifySize(a.observedSources,[3 144 4]);
            tc.verifySize(a.sensors,[12 144 4]);
            tc.verifyEqual(a.trueA(1,2,:),zeros(1,1,2));
            tc.verifyEqual(nnz(triu(a.truth,0)),0);
        end
        function fullAcyclicGraphAssignsOneEdgePerSelection(tc)
            cfg=localConfig();opts=localOptions();
            cfg.nSources=5;
            cfg.nInteractions=cfg.nSources*(cfg.nSources-1)/2;
            sim=asct_m6_generate(cfg,opts);
            tc.verifyEqual(nnz(sim.truth),cfg.nInteractions);
            tc.verifyEqual(nnz(triu(sim.truth,0)),0);
            tc.verifyTrue(sim.truth(2,1));
            tc.verifyEqual(nnz(sim.trueA(:,:,cfg.lag)),cfg.nInteractions);
        end
        function erpChangesOnlyEvokedAdditionForPairedSeed(tc)
            cfg=localConfig();opts=localOptions();
            a=asct_m6_generate(cfg,opts);
            cfg.evokedAmplitude=1;
            b=asct_m6_generate(cfg,opts);
            tc.verifyEqual(a.trueA,b.trueA);
            tc.verifyEqual(a.endogenousSources,b.endogenousSources);
            expected=repmat(b.evoked,1,1,opts.nTrials);
            tc.verifyEqual(b.observedSources-a.observedSources,expected, ...
                'AbsTol',1e-12);
        end
        function distanceAffectsLeadfieldNotCausalGraph(tc)
            cfg=localConfig();opts=localOptions();
            a=asct_m6_generate(cfg,opts);
            cfg.distanceCm=6;
            b=asct_m6_generate(cfg,opts);
            tc.verifyEqual(a.trueA,b.trueA);
            tc.verifyEqual(a.endogenousSources,b.endogenousSources);
            tc.verifyEqual(a.sensorPositionsCm,b.sensorPositionsCm);
            tc.verifyGreaterThan(norm(a.mixing-b.mixing,'fro'),0.01);
        end
        function noisePowerMatchesVectorizedSensorProjection(tc)
            cfg=localConfig();opts=localOptions();
            sim=asct_m6_generate(cfg,opts);
            projected=sim.mixing*reshape(sim.endogenousSources,cfg.nSources,[]);
            expected=mean(projected(:).^2)/10^(cfg.snrDb/10);
            tc.verifyEqual(sim.sensorNoiseVariance,expected,'RelTol',1e-12);
            tc.verifySize(sim.sensors,[opts.nSensors opts.nSamples opts.nTrials]);
        end
        function rejectsNonScalarMontageCoverage(tc)
            cfg=localConfig();opts=localOptions();
            opts.sensorCoverageDistanceCm=[6 8];
            tc.verifyError(@()asct_m6_generate(cfg,opts),'ASCT:M6:Sensors');
        end
        function zeroEdgeTruthAndRange(tc)
            cfg=localConfig();opts=localOptions();
            cfg.nInteractions=0;
            a=asct_m6_generate(cfg,opts);
            tc.verifyFalse(any(a.truth(:)));
            cfg.nSources=13;
            tc.verifyError(@()asct_m6_generate(cfg,opts),'ASCT:M6:Sources');
        end
        function boundedFactorialPrunesImpossibleGraphs(tc)
            f=struct('nSources',[3 5],'distanceCm',[1.5 6], ...
                'nInteractions',[2 8],'strength',0.3,'lag',2,'snrDb',10);
            cfg=asct_m6_factorial(f,20);
            tc.verifyEqual(numel(cfg),6);
            tc.verifyTrue(all([cfg.nSources]>=3));
            tc.verifyTrue(all([cfg.nInteractions]<= ...
                [cfg.nSources].*([cfg.nSources]-1)/2));
            tc.verifyError(@()asct_m6_factorial(f,5),'ASCT:M6:Grid');
        end
        function studyWritesIndependentGroundTruth(tc)
            output=tempname;
            tc.addTeardown(@()localCleanup(output));
            opts=struct('nReplicates',2,'nBootstrap',100,'seed',42, ...
                'simulation',localOptions(), ...
                'scenarios',rmfield(localConfig(),{'evokedAmplitude','varianceDrift','simSeed'}), ...
                'mvar',struct('orderMode','fixed','fixedOrder',2, ...
                'maxMvarOrder',3,'varNorm',false,'removeERP',false));
            [T,S]=asct_m6_study(output,opts);
            tc.verifyEqual(height(T),2);
            tc.verifyEqual(height(S),1);
            tc.verifyNotEqual(T.simSeed(1),T.simSeed(2));
            tc.verifyTrue(all(isfinite(T.inverseF1)));
            tc.verifyTrue(all(isfinite(T.sourceRMSE)));
            tc.verifyTrue(isfile(fullfile(output,'m6_results.mat')));
            t=load(fullfile(output,'m6_results.mat'),'truthRecords');
            tc.verifyEqual(nnz(t.truthRecords{1}.truth),2);
            tc.verifyError(@()asct_m6_study(output,opts), ...
                'ASCT:Study:OutputExists');
        end
    end
end
function cfg=localConfig()
cfg=struct('nSources',3,'distanceCm',1.5,'nInteractions',2, ...
    'strength',0.3,'lag',2,'snrDb',12,'simSeed',357, ...
    'evokedAmplitude',0,'varianceDrift',0);
end
function opts=localOptions()
opts=struct('fs',64,'nSamples',144,'nTrials',4,'nSensors',12);
end
function localCleanup(path)
if isfolder(path),rmdir(path,'s');end
end
