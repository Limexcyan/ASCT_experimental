classdef TestMultiverseM9 < matlab.unittest.TestCase
    % Directed statistics, coefficient errors, independent-replicate CI.
    methods (TestClassSetup)
        function paths(tc)
            root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'multiverse'));
            tc.addTeardown(@()rmpath(fullfile(root,'multiverse')));
        end
    end
    methods (Test)
        function exactKnownEdgeHasZeroLagAndStrengthError(tc)
            A=zeros(3,3,2);
            A(:,:,1)=0.25*eye(3);
            A(2,1,2)=0.6;
            fit=struct('A',A,'Adtf',A,'order',2, ...
                'diagnostics',struct('spectralRadius',0.25,'stable',true, ...
                    'maxLag1ResidualCorrelation',0, 'maxVarianceRatio',1, ...
                    'evokedRMSFraction',0));
            truth=false(3);truth(2,1)=true;
            m=asct_m9_evaluate(fit,A,truth,128,linspace(1,35,30),0.1);
            tc.verifyEqual(m.nTrueEdges,1);
            tc.verifyEqual(m.lagMAE,0);
            tc.verifyEqual(m.strengthMAE,0);
            tc.verifyGreaterThanOrEqual(m.tp,1);
        end
        function bootstrapIsReproducibleAndRestoresRng(tc)
            state=rng;
            a=asct_m9_bootstrap((1:10)',100,33);
            b=asct_m9_bootstrap((1:10)',100,33);
            tc.verifyEqual(a,b);
            tc.verifyEqual(rng,state);
            tc.verifyEqual(a.mean,5.5);
            tc.verifyLessThanOrEqual(a.ciLow,a.mean);
            tc.verifyGreaterThanOrEqual(a.ciHigh,a.mean);
            tc.verifyError(@()asct_m9_bootstrap(1,100,33), ...
                'ASCT:M9:Samples');
        end
        function batchedBootstrapMatchesScalarDrawReference(tc)
            values=(1:7)';nDraws=105;seed=21;
            oldRng=rng;
            tc.addTeardown(@()rng(oldRng));
            rng(seed,'twister');
            reference=zeros(nDraws,1);
            for k=1:nDraws
                ix=randi(numel(values),numel(values),1);
                reference(k)=mean(values(ix));
            end
            actual=asct_m9_bootstrap(values,nDraws,seed);
            sorted=sort(reference);
            tc.verifyEqual(actual.ciLow,sorted(ceil(0.025*nDraws)), ...
                'AbsTol',1e-14);
            tc.verifyEqual(actual.ciHigh,sorted(ceil(0.975*nDraws)), ...
                'AbsTol',1e-14);
        end
        function batchedBootstrapPreservesIndependentMetricColumns(tc)
            x=(1:9)';
            single=asct_m9_bootstrap(x,150,37);
            both=asct_m9_bootstrap([x 2*x+1],150,37);
            tc.verifyEqual(both.mean,[5 11]);
            tc.verifyEqual(both.ciLow, ...
                [single.ciLow 2*single.ciLow+1],'AbsTol',1e-12);
            tc.verifyEqual(both.ciHigh, ...
                [single.ciHigh 2*single.ciHigh+1],'AbsTol',1e-12);
        end
        function pairedERPRequiresSameSimulation(tc)
            T=table([1;1],[12;12],[5;5],[1;1],[0;0], ...
                {'fixed';'fixed'},[0;0],[false;true],[0.3;0.5], ...
                [0.4;0.2], ...
                'VariableNames',{'replicate','simSeed','nROIs', ...
                'evokedAmplitude','varianceDrift','orderMode', ...
                'varNorm','removeERP','f1','falsePositiveRate'});
            P=asct_m9_paired_erp(T);
            tc.verifyEqual(height(P),1);
            tc.verifyEqual(P.fprReduction,0.2,'AbsTol',1e-12);
            tc.verifyEqual(P.f1Gain,0.2,'AbsTol',1e-12);
            T.simSeed(2)=13;
            tc.verifyError(@()asct_m9_paired_erp(T), 'ASCT:M9:Pairing');
        end
        function groupingDoesNotConfuseDelimitersOrMissingLambda(tc)
            % Composite string keys would merge these distinct groups.
            T=table(["a|b";"a|b";"a";"a"], ...
                ["c";"c";"b|c";"b|c"], ...
                [NaN;NaN;0.1;0.1],[10;11;12;13], ...
                [0.2;0.4;0.6;0.8], ...
                'VariableNames',{'scenario','setting','lambda','simSeed','f1'});
            S=asct_m9_table_summary(T, ...
                {'scenario','setting','lambda'},{'f1'},100,42);
            tc.verifyEqual(height(S),2);
            tc.verifyEqual(S.mean_f1,[0.3;0.7],'AbsTol',1e-12);
            tc.verifyTrue(isnan(S.lambda(1)));
            tc.verifyEqual(S.nReplicates,[2;2]);
        end
        function rejectsDuplicateSeedsWithinBootstrapGroup(tc)
            T=table([1;1],[7;7],[0.1;0.5], ...
                'VariableNames',{'scenario','simSeed','f1'});
            tc.verifyError(@()asct_m9_table_summary(T, ...
                {'scenario'},{'f1'},100,9), ...
                'ASCT:M9:DuplicateReplicate');
        end
        function multipleERPPairsPreserveTypedGrouping(tc)
            T=table([1;1;1;1],[11;11;12;12], ...
                [5;5;5;5],[1;1;1;1],[0;0;0;0], ...
                {'fixed';'fixed';'aic';'aic'}, ...
                [0;0;1;1],[false;true;false;true], ...
                [0.4;0.6;0.2;0.3],[0.3;0.1;0.2;0.1], ...
                'VariableNames',{'replicate','simSeed','nROIs', ...
                'evokedAmplitude','varianceDrift','orderMode', ...
                'varNorm','removeERP','f1','falsePositiveRate'});
            P=asct_m9_paired_erp(T);
            tc.verifyEqual(height(P),2);
            tc.verifyEqual(P.simSeed,[11;12]);
            tc.verifyEqual(P.fprReduction,[0.2;0.1],'AbsTol',1e-12);
        end
        function summaryGroupsCorrectly(tc)
            T=table([1;1;2;2], [1;2;1;2],[0.2;0.4;0.6;0.8], ...
                'VariableNames',{'scenario','replicate','f1'});
            S=asct_m9_table_summary(T,{'scenario'},{'f1'},100,42);
            tc.verifyEqual(height(S),2);
            tc.verifyEqual(S.nReplicates,[2;2]);
            tc.verifyEqual(S.mean_f1,[0.3;0.7],'AbsTol',1e-12);
            tc.verifyTrue(all(isfinite(S.low_f1)));
        end
    end
end
