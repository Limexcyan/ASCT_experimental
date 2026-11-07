ana1 = load('/mnt/iSCSI3/Exp2/heart_brain/exp/dtf/ana1/6_ICA2/ica2stat.mat');
ica2stat = ana1.ica2stat

icap = ica2stat(:,9);
icap(1) = [];
icapn1 = cell2mat(icap);
% figure; hist(icapn, 20)

anat = load('/mnt/iSCSI3/Exp2/heart_brain/exp/dtf/anat/6_ICA2/ica2stat.mat');
ica2stat = anat.ica2stat

icap = ica2stat(:,9);
icap(1) = [];
icapnt = cell2mat(icap);
% figure; hist(icapn, 20)

figure;
histogram(icapn1,'facealpha',.7,'edgecolor','none', 'NumBins', 20);
hold on;
histogram(icapnt,'facealpha',.3,'edgecolor','none', 'NumBins', 20);