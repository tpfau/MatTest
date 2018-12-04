function [results, resultTable, coverageData] = runTestSuite(testNames, skipErrorID, workingDir, sourceFiles)
% This function runs all tests (i.e. files starting with 'test' in the
% CBTDIR/test/ folder and returns the status.
% It can distinguish between skipped and Failed tests. A test is considered
% to be skipped if it throws an error with the given skipID.
%
% INPUTS:
%
%    testNames:        only run tests matching the wildcard given in
%                      testNames. (e.g. ['test' filesep '**' filesep 'test*.m'])
%    skipErrorID:      name of the ID to be used to indicate, that an
%                      error, is actually supposed to indicate a skipped test 
%    workingDir:       The working directory for the test suite.
%    sourceDir:        The source directory
%
% OUTPUTS:
%
%    results:          A structure array with one entry per test and the following fields:
%
%                       - `.passed`: true if the test passed otherwise false
%                       - `.skipped`: true if the test was skipped otherwise false
%                       - `.failed`: true if the test failed, or was skipped, otherwise false
%                       - `.status`: a string representing the status of the test ('failed','skipped' or'passed')
%                       - `.fileName`: the fileName of the test
%                       - `.time`: the duration of the test (if passed otherwise NaN)
%                       - `.statusMessage`: Informative string about potential problems
%                       - `.Error`: Error message received from a failed or skipped test
%    resultTable:      A Table with details of the results.
%    coverageData:     Coverage data for all files.
%
% Author:
%    - Thomas Pfau Jan 2018.

global TESTSUITE_SKIP_ERROR_ID

% set the error ID that is considered to be used as a skip.
TESTSUITE_SKIP_ERROR_ID = skipErrorID;

% go to the test directory.
currentDir = cd(workingDir);
coverageData = setupCoverageData(sourceFiles);
% get all names of test files
testFiles = rdir(testNames);
testFileNames = {testFiles.name};

% save the current globals (all tests should have the same environment when
% starting) and path 
environment = getEnvironment();

% save the current warning state
warnstate = warning();

% run the tests and show outputs.
for i = 1:numel(testFileNames)
    % shut down any existing parpool.
    try
        % test if there is a parpool that we should shut down before the next test.
        p = gcp('nocreate');
        delete(p);
    catch
        % do nothing
    end

    % reset the globals
    restoreEnvironment(environment)

    % reset the warning state
    warning(warnstate);

    [~,file,ext] = fileparts(testFileNames{i});
    testName = file;
    fprintf('****************************************************\n\n');
    fprintf('Running %s\n\n',testName);
    results(i) = runScriptFile([file ext]);
    fprintf('\n\n%s %s!\n',testName,results(i).status);
    if ~results(i).passed
        if results(i).skipped
            fprintf('Reason:\n%s\n',results(i).statusMessage);
        else
            trace = results(i).Error.getReport();
            tracePerLine = strsplit(trace,'\n');
            testSuitePosition = find(cellfun(@(x) ~isempty(strfind(x, 'runTestSuite')),tracePerLine));
            trace = sprintf(strjoin(tracePerLine(1:(testSuitePosition-7)),'\n')); % Remove the testSuiteTrace.
            fprintf('Reason:\n%s\n',trace);
        end
    end
    coverageData = updateCoverageData(coverageData);
    fprintf('\n\n****************************************************\n');
end

% create a table from the fields
resultTable= table({results.fileName}',{results.status}',[results.passed]',[results.skipped]',...
                            [results.failed]',[results.time]',{results.statusMessage}',...
                            'VariableNames',{'TestName','Status','Passed','Skipped','Failed','Time','Details'});
% change back to the original directory.
cd(currentDir)
end
