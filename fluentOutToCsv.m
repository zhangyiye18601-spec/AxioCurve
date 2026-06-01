function outputFile = fluentOutToCsv(inputFile, outputDir)
%FLUENTOUTTOCSV Convert a Fluent monitor .out file to a header-aligned CSV.

inputFile = char(inputFile);
outputDir = char(outputDir);

if ~isfile(inputFile)
    error('AxioCurve:FluentOut:InputNotFound', '未找到输入文件: %s', inputFile);
end
if ~isfolder(outputDir)
    error('AxioCurve:FluentOut:OutputDirNotFound', '未找到输出文件夹: %s', outputDir);
end

fid = fopen(inputFile, 'r');
if fid < 0
    error('AxioCurve:FluentOut:OpenFailed', '无法打开输入文件: %s', inputFile);
end
cleaner = onCleanup(@() fclose(fid));

fgetl(fid);
fgetl(fid);
headerLine = fgetl(fid);
if ~ischar(headerLine)
    error('AxioCurve:FluentOut:MissingHeader', '文件缺少表头行: %s', inputFile);
end

tokens = regexp(headerLine, '"([^"]*)"', 'tokens');
headers = cellfun(@(token) token{1}, tokens, 'UniformOutput', false);
if isempty(headers)
    error('AxioCurve:FluentOut:MissingHeader', '未能从第三行提取表头: %s', inputFile);
end

rawLines = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
dataLines = rawLines{1};
dataLines = dataLines(~cellfun(@(line) isempty(strtrim(line)), dataLines));

numColumns = numel(headers);
data = zeros(numel(dataLines), numColumns);
for row = 1:numel(dataLines)
    fields = regexp(strtrim(dataLines{row}), '\s+', 'split');
    if numel(fields) ~= numColumns
        error('AxioCurve:FluentOut:ColumnMismatch', ...
            '第 %d 行数据列数为 %d，但表头列数为 %d: %s', row + 3, numel(fields), numColumns, inputFile);
    end
    data(row, :) = str2double(fields);
end

[~, name] = fileparts(inputFile);
outputFile = fullfile(outputDir, [name '.csv']);
writecell([headers; num2cell(data)], outputFile);
end
