clear; clc; close all

mainScripts = ["AllImages.m"; "AllImages_Test.m"; "MultiBendLoadCellTest_9_22.m"; "OffAxisLoadCellTest_9_25.m"; "MultipleBendAngleFits_10_14"; "MultipleCircleFits_10_14"; "MultipleOrderFits_10_14"]
fullFileList = [];
fullProductList = [];

for a = 1:length(mainScripts)
    [thisFileList, thisProductList] = matlab.codetools.requiredFilesAndProducts(mainScripts(a));

    fullFileList = [fullFileList; thisFileList'];
    thisProductList.Name

end

reducedFileList = unique(fullFileList)

