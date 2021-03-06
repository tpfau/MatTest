function writeCoverage(coverageData, jsonFile)
% Write the coverage data stored in the coverageData Struct into a json
% file. 
% USAGE:
%    writeCoverage(coverageData)
%
% INPUT:
%    coverageData:      A Data struct with the coverage data having the
%                       following fields
%                        * .fileName - the file name
%                        * .relevantLines - a n x 2 double array with n being the number of relevant lines in the file, while the first column indicates the line number and the second column indicates the number of executions
%                        * .lineCount - the number of lines in the file.
%
%    jsonFile:        The name of the outputfile (e.g. 'coverage.json')
%
%
% AUTHOR:       Thomas Pfau 2018

if ischar(jsonFile)
    jsonFile = fopen(jsonFile,'w');
end
fprintf(jsonFile,'{\n"service_job_id": "none",\n"service_name": "none",\n"source_files": [\n');

for i = 1:numel(coverageData)
    if i > 1
        fprintf(jsonFile,',');
    end
    fprintf(jsonFile,'{ "name": "%s",\n',coverageData(i).fileName);
    [md5] = getMD5Checksum(coverageData(i).fileName);
    fprintf(jsonFile,'"source_digest": "%s",\n',md5);
    coverage = repmat({'null'},coverageData(i).lineCount,1);
    coverage(coverageData(i).relevantLines(:,1)) = arrayfun(@num2str, coverageData(i).relevantLines(:,2),'Uniform',0);
    fprintf(jsonFile,'"coverage": [%s]\n }\n',strjoin(coverage,','));    
end

fprintf(jsonFile,']\n}\n');

fclose(jsonFile);

for i = 1:numel(coverageData)
    execLines = false(coverageData(i).lineCount,1);
    executedLines = execLines;
    executableLines = execLines;
    execution = coverageData(i).relevantLines;    
    execcount = zeros(coverageData(i).lineCount,1);
    execcount(execution(:,1)) = execution(:,2);
    executableLines(execution(:,1)) = true;
    executedLines(execution(execution(:,2)>0,1)) = true;    
    coverageData(i).execcount = execcount;
    coverageData(i).executableLines = executableLines;
    coverageData(i).executedLines = executedLines;
end

write_bunch_html_dir(coverageData,'html_coverage')

