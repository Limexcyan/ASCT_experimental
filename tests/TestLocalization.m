classdef TestLocalization < matlab.unittest.TestCase
    % Small linear inverse-problem reference, not ASCT source localization.
    methods (Test)
        function noiselessFullRankRecovery(testCase)
            L = [1 0.2; 0.1 1; 0.4 -0.3];
            S = [1 0 -2 1; 0 2 1 -1];
            sensors = L*S;
            recovered = L\sensors;
            testCase.verifySize(recovered,size(S));
            testCase.verifyEqual(recovered,S,'AbsTol',1e-12);
        end
        function tikhonovSolutionSatisfiesNormalEquations(testCase)
            L = [1 0.2; 0.1 1; 0.4 -0.3];
            X = [1 -1; 2 0; 0 1];
            lambda = 0.1;
            recovered = (L'*L + lambda*eye(2))\(L'*X);
            residual = (L'*L + lambda*eye(2))*recovered - L'*X;
            testCase.verifyLessThan(norm(residual,'fro'),1e-11);
            testCase.verifyTrue(all(isfinite(recovered(:))));
        end
    end
end
