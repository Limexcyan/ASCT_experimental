classdef TestMultiverseM7 < matlab.unittest.TestCase
    % M7 synthetic inverse proxy is not an implementation of FieldTrip MNE.
    methods (TestClassSetup)
        function paths(tc)
            root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'multiverse'));
            tc.addTeardown(@()rmpath(fullfile(root,'multiverse')));
        end
    end
    methods (Test)
        function prunedLambdaCovFactorGrid(tc)
            [f,keep,nRuns]=asct_m7_realdata_factors( ...
                struct('lambda',0.05),[0.05 0.1],[0 0.5]);
            tc.verifyEqual(nRuns,6);
            mv=struct('factors',struct('loc',f), ...
                'includeFcn',keep,'maxRuns',nRuns);
            specs=asct_multiverse_realdata_grid(mv);
            tc.verifyNumElements(specs,6);
            tc.verifyTrue(all([specs.startStep]==8));
            for i=1:numel(specs)
                if strcmp(specs(i).changes.loc.norm,'cov')
                    tc.verifyEqual(specs(i).changes.loc.lambda,0.05);
                end
            end
        end
        function inverseDimensionsAndRegularization(tc)
            cfg=localConfig();sim=asct_m6_generate(cfg,localOptions());
            loc=struct('norm','lambda','lambda',0.01,'depthWeight',0);
            [a,ia]=asct_m7_inverse_proxy(sim,loc);
            loc.lambda=1;
            [b,ib]=asct_m7_inverse_proxy(sim,loc);
            tc.verifySize(a,size(sim.trueSources));
            tc.verifyGreaterThan(norm(a(:)-b(:)),0.01);
            tc.verifyGreaterThan(ib.regularization,ia.regularization);
            tc.verifyTrue(isfinite(ia.sourceRMSE));
            tc.verifyTrue(ia.inverseProxy);
            loc=struct('norm','cov','depthWeight',0.5);
            [c,ic]=asct_m7_inverse_proxy(sim,loc);
            tc.verifySize(c,size(sim.trueSources));
            tc.verifyGreaterThan(ic.regularization,0);
        end
        function inverseProxyMatchesReferenceRidgeFormula(tc)
            cfg=localConfig();sim=asct_m6_generate(cfg,localOptions());
            loc=struct('norm','lambda','lambda',0.08,'depthWeight',0.5);
            [estimated,info]=asct_m7_inverse_proxy(sim,loc);
            L=sim.mixing;
            weights=sum(L.^2,1)'.^(-loc.depthWeight/2);
            G=bsxfun(@times,L,weights');
            W=diag(weights)*((G'*G+info.regularization*eye(size(G,2)))\G');
            expected=reshape(W*reshape(sim.sensors,size(L,1),[]),size(estimated));
            tc.verifyEqual(estimated,expected,'AbsTol',1e-10);
        end
        function syntheticFactorialWritesOutput(tc)
            output=tempname;
            tc.addTeardown(@()localCleanup(output));
            cfg=localConfig();cfg=rmfield(cfg,'simSeed');
            opts=struct('source',cfg,'simulation',localOptions(), ...
                'lambdas',[0.01 0.1],'depthWeights',[0 0.5], ...
                'nReplicates',2,'nBootstrap',100,'seed',12, ...
                'mvar',struct('orderMode','fixed','fixedOrder',2, ...
                    'maxMvarOrder',3,'varNorm',false,'removeERP',false));
            [T,summary]=asct_m7_study(output,opts);
            tc.verifyEqual(height(T),12);
            tc.verifyEqual(height(summary),6);
            tc.verifyTrue(isfile(fullfile(output,'m7_cases.csv')));
            tc.verifyTrue(all(isfinite(T.sourceRMSE)));
        end
    end
end
function cfg=localConfig()
cfg=struct('nSources',5,'distanceCm',2,'nInteractions',3, ...
    'strength',0.3,'lag',2,'snrDb',10,'simSeed',234);
end
function o=localOptions()
o=struct('fs',64,'nSamples',144,'nTrials',4,'nSensors',14);
end
function localCleanup(path)
if isfolder(path),rmdir(path,'s');end
end
