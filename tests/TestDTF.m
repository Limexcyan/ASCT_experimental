classdef TestDTF < matlab.unittest.TestCase
    % Reference spectral transfer function of a known VAR(1).
    % Convention: H(target,source), i.e. X -> Y is H(2,1).
    % The test does NOT yet invoke ASCT/multar DTF routines.
    methods (Test)
        function knownXtoYDirection(testCase)
            A = [0.35 0.00; 0.40 0.25]; % X drives Y only
            f = linspace(0,0.5,65);
            d = TestDTF.referenceDTF(A,f);
            testCase.verifySize(d,[2,2,65]);
            xy = squeeze(d(2,1,:));
            yx = squeeze(d(1,2,:));
            testCase.verifyGreaterThan(mean(xy),0.01);
            testCase.verifyLessThan(max(abs(yx)),1e-12);
            testCase.verifyTrue(all(isfinite(d(:))));
            % Row normalized by target: sum(source^2)=1.
            normed = squeeze(sum(d.^2,2));
            testCase.verifyEqual(normed,ones(2,65),'AbsTol',1e-10);
        end
        function uncoupledModelHasNoOffDiagonalDTF(testCase)
            A = diag([0.35,0.25]);
            d = TestDTF.referenceDTF(A,linspace(0,0.5,33));
            testCase.verifyLessThan(max(abs(squeeze(d(1,2,:)))),1e-12);
            testCase.verifyLessThan(max(abs(squeeze(d(2,1,:)))),1e-12);
        end
    end
    methods (Static, Access=private)
        function d = referenceDTF(A,f)
            n = size(A,1);
            d = zeros(n,n,numel(f));
            for k = 1:numel(f)
                H = (eye(n)-A*exp(-2i*pi*f(k)))\eye(n);
                power = abs(H).^2;
                d(:,:,k) = sqrt(power ./ sum(power,2));
            end
        end
    end
end
