classdef LineAnimationApp < matlab.apps.AppBase

    % Properties (UI Components)
    properties (Access = public)
        UIFigure      matlab.ui.Figure
        GridLayout    matlab.ui.container.GridLayout
        
        % Left Panel Components
        LeftPanel        matlab.ui.container.Panel
        FindReplacePanel matlab.ui.container.Panel 
        FindEdit         matlab.ui.control.EditField
        ReplaceEdit      matlab.ui.control.EditField
        ReplaceBtn       matlab.ui.control.Button
        SelectAllYBtn    matlab.ui.control.Button 
        ClearYBtn        matlab.ui.control.Button 
        DataTable        matlab.ui.control.Table
        
        % Middle Panel Components
        MiddlePanel   matlab.ui.container.Panel
        MiddleTabs    matlab.ui.container.TabGroup
        DataTab       matlab.ui.container.Tab
        AxisTab       matlab.ui.container.Tab
        StyleTab      matlab.ui.container.Tab
        ExportTab     matlab.ui.container.Tab
        LoadBtn       matlab.ui.control.Button
        
        AxesPanel     matlab.ui.container.Panel
        XMinEdit      matlab.ui.control.NumericEditField
        XMaxEdit      matlab.ui.control.NumericEditField
        YMinEdit      matlab.ui.control.NumericEditField
        YMaxEdit      matlab.ui.control.NumericEditField
        XTickSpaceEdit matlab.ui.control.NumericEditField 
        YTickSpaceEdit matlab.ui.control.NumericEditField 
        YRightMinEdit matlab.ui.control.NumericEditField
        YRightMaxEdit matlab.ui.control.NumericEditField
        YRightTickSpaceEdit matlab.ui.control.NumericEditField
        XFormatDrop   matlab.ui.control.DropDown
        XDecEdit      matlab.ui.control.NumericEditField
        YFormatDrop   matlab.ui.control.DropDown
        YDecEdit      matlab.ui.control.NumericEditField
        YRightFormatDrop matlab.ui.control.DropDown
        YRightDecEdit matlab.ui.control.NumericEditField
        
        CurvePanel    matlab.ui.container.Panel
        ColorDrop     matlab.ui.control.DropDown
        FontDrop      matlab.ui.control.DropDown
        AxisWidthEdit matlab.ui.control.NumericEditField
        FontSizeEdit  matlab.ui.control.NumericEditField
        LineWidthEdit matlab.ui.control.NumericEditField
        LgdFontEdit   matlab.ui.control.NumericEditField
        LegendShapeDrop matlab.ui.control.DropDown
        MarkerSizeEdit matlab.ui.control.NumericEditField
        WidthEdit     matlab.ui.control.NumericEditField  
        HeightEdit    matlab.ui.control.NumericEditField 
        DPIEdit       matlab.ui.control.NumericEditField 
        IntervalEdit  matlab.ui.control.NumericEditField
        PreviewBtn    matlab.ui.control.Button
        DrawBtn       matlab.ui.control.Button
        ResetBtn      matlab.ui.control.Button
        
        ExportPanel   matlab.ui.container.Panel
        ExportFormatDrop matlab.ui.control.DropDown
        ExportBtn     matlab.ui.control.Button
        ProgressBg    matlab.ui.container.Panel
        ProgressFill  matlab.ui.container.Panel
        ProgressText  matlab.ui.control.Label
        AuthorLabel   matlab.ui.control.Label
        StatusLabel   matlab.ui.control.Label

        XStyleOverrideChk matlab.ui.control.CheckBox
        YLeftStyleOverrideChk matlab.ui.control.CheckBox
        YRightStyleOverrideChk matlab.ui.control.CheckBox
        XAxisColorBtn matlab.ui.control.Button
        XTitleColorBtn matlab.ui.control.Button
        YLeftAxisColorBtn matlab.ui.control.Button
        YLeftTitleColorBtn matlab.ui.control.Button
        YRightAxisColorBtn matlab.ui.control.Button
        YRightTitleColorBtn matlab.ui.control.Button
        XAxisFontDrop matlab.ui.control.DropDown
        YLeftAxisFontDrop matlab.ui.control.DropDown
        YRightAxisFontDrop matlab.ui.control.DropDown
        XAxisFontSizeEdit matlab.ui.control.NumericEditField
        YLeftAxisFontSizeEdit matlab.ui.control.NumericEditField
        YRightAxisFontSizeEdit matlab.ui.control.NumericEditField
        
        % Right Panel Components
        RightPanel    matlab.ui.container.Panel
        AxesWrapper   matlab.ui.container.Panel 
        PlotArea      matlab.ui.container.Panel 
        UIAxes        matlab.graphics.axis.Axes 
        BottomLayout  matlab.ui.container.GridLayout 
        
        XLabelEdit    matlab.ui.control.EditField
        YLabelEdit    matlab.ui.control.EditField
        YRightLabelEdit matlab.ui.control.EditField
        
        % 坐标轴开关组
        FontBoldChk   matlab.ui.control.CheckBox
        TickOutChk    matlab.ui.control.CheckBox 
        GridLineChk   matlab.ui.control.CheckBox
        
        % 图例开关组
        LgdVisibleChk matlab.ui.control.CheckBox
        LgdBgChk      matlab.ui.control.CheckBox
        LgdBorderChk  matlab.ui.control.CheckBox
        LgdColsEdit   matlab.ui.control.NumericEditField 
        
        LgdXSlider    matlab.ui.control.Slider 
        LgdXEdit      matlab.ui.control.NumericEditField
        LgdYSlider    matlab.ui.control.Slider 
        LgdYEdit      matlab.ui.control.NumericEditField
        
        % Data & State storage
        RawData
        Headers
        H_Lines
        H_LinesLeft
        H_LinesRight
        X_Data_Plot
        Y_Data_Plot
        Y_Left_Data_Plot
        Y_Right_Data_Plot
        LegendLabels
        LegendLabelsLeft
        LegendLabelsRight
        HasRightAxis = false;
        
        CurrentFrame = 1;
        IsPlaying = false;
        RecentColors = [];
    end

    methods (Access = private)

        function safeRun(app, taskFcn, context)
            try
                taskFcn();
            catch ME
                app.handleRuntimeError(ME, context);
            end
        end

        function handleRuntimeError(app, ME, context)
            if nargin < 3 || isempty(context), context = '运行'; end
            msg = sprintf('%s过程中出现错误:\n%s', context, ME.message);
            try
                app.writeErrorLog(ME, context);
            catch
            end
            try
                if isvalid(app) && isvalid(app.UIFigure)
                    uialert(app.UIFigure, msg, '程序错误');
                    app.restoreMainWindow();
                else
                    warning('%s', msg);
                end
            catch
                warning('%s', msg);
            end
        end

        function writeErrorLog(~, ME, context)
            logDir = fullfile(getenv('USERPROFILE'), 'Documents', 'LineAnimationAppLogs');
            if ~isfolder(logDir), mkdir(logDir); end
            logFile = fullfile(logDir, 'LineAnimationApp_error.log');
            fid = fopen(logFile, 'a');
            if fid < 0, return; end
            cleaner = onCleanup(@() fclose(fid));
            fprintf(fid, '\n[%s] %s\n', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')), context);
            fprintf(fid, '%s: %s\n', ME.identifier, ME.message);
            for k = 1:numel(ME.stack)
                fprintf(fid, '  at %s line %d\n', ME.stack(k).name, ME.stack(k).line);
            end
            clear cleaner;
        end

        function items = getColorMapNames(~)
            items = {'Nature/NPG', 'Lancet', 'AAAS', 'NEJM', 'JAMA', 'Okabe-Ito', ...
                'Tableau', 'ColorBrewer Set1', 'ColorBrewer Set2', 'ColorBrewer Dark2', ...
                'parula', 'turbo', 'jet', 'lines', 'hsv', 'hot', 'cool', 'spring', ...
                'summer', 'autumn', 'winter', 'gray', 'bone', 'copper', 'colorcube'};
        end

        function colors = getColorMap(app, cmapName, n)
            if nargin < 3 || isempty(n) || n <= 0
                colors = zeros(0, 3);
                return;
            end
            key = lower(strtrim(cmapName));
            switch key
                case {'nature/npg', 'nature', 'npg'}
                    base = app.hexToRgb({'E64B35', '4DBBD5', '00A087', '3C5488', 'F39B7F', '8491B4', '91D1C2', 'DC0000', '7E6148', 'B09C85'});
                    colors = app.expandPalette(base, n);
                case 'lancet'
                    base = app.hexToRgb({'00468B', 'ED0000', '42B540', '0099B4', '925E9F', 'FDAF91', 'AD002A', 'ADB6B6', '1B1919'});
                    colors = app.expandPalette(base, n);
                case 'aaas'
                    base = app.hexToRgb({'3B4992', 'EE0000', '008B45', '631879', '008280', 'BB0021', '5F559B', 'A20056', '808180'});
                    colors = app.expandPalette(base, n);
                case 'nejm'
                    base = app.hexToRgb({'BC3C29', '0072B5', 'E18727', '20854E', '7876B1', '6F99AD', 'FFDC91', 'EE4C97'});
                    colors = app.expandPalette(base, n);
                case 'jama'
                    base = app.hexToRgb({'374E55', 'DF8F44', '00A1D5', 'B24745', '79AF97', '6A6599', '80796B'});
                    colors = app.expandPalette(base, n);
                case 'okabe-ito'
                    base = app.hexToRgb({'000000', 'E69F00', '56B4E9', '009E73', 'F0E442', '0072B2', 'D55E00', 'CC79A7'});
                    colors = app.expandPalette(base, n);
                case 'tableau'
                    base = app.hexToRgb({'4E79A7', 'F28E2B', 'E15759', '76B7B2', '59A14F', 'EDC948', 'B07AA1', 'FF9DA7', '9C755F', 'BAB0AC'});
                    colors = app.expandPalette(base, n);
                case 'colorbrewer set1'
                    base = app.hexToRgb({'E41A1C', '377EB8', '4DAF4A', '984EA3', 'FF7F00', 'FFFF33', 'A65628', 'F781BF', '999999'});
                    colors = app.expandPalette(base, n);
                case 'colorbrewer set2'
                    base = app.hexToRgb({'66C2A5', 'FC8D62', '8DA0CB', 'E78AC3', 'A6D854', 'FFD92F', 'E5C494', 'B3B3B3'});
                    colors = app.expandPalette(base, n);
                case 'colorbrewer dark2'
                    base = app.hexToRgb({'1B9E77', 'D95F02', '7570B3', 'E7298A', '66A61E', 'E6AB02', 'A6761D', '666666'});
                    colors = app.expandPalette(base, n);
                otherwise
                    try
                        colors = feval(cmapName, n);
                    catch
                        colors = lines(n);
                    end
                    if strcmpi(cmapName, 'jet')
                        colors = flipud(colors);
                    end
                    if size(colors, 2) > 3
                        colors = colors(:, 1:3);
                    end
            end
        end

        function rgb = hexToRgb(~, hexList)
            rgb = zeros(numel(hexList), 3);
            for k = 1:numel(hexList)
                h = char(hexList{k});
                rgb(k, :) = [hex2dec(h(1:2)), hex2dec(h(3:4)), hex2dec(h(5:6))] / 255;
            end
        end

        function colors = expandPalette(~, base, n)
            idx = mod(0:n-1, size(base, 1)) + 1;
            colors = base(idx, :);
        end

        function setYAxisExponentZero(~, ax_target)
            for k = 1:numel(ax_target.YAxis)
                ax_target.YAxis(k).Exponent = 0;
            end
        end

        function fonts = getAvailableFonts(~)
            preferred = {'Times New Roman', 'Arial', 'Calibri', 'Cambria', 'Georgia', ...
                'Helvetica', 'Verdana', 'Tahoma', 'Consolas', 'Courier New', ...
                'Microsoft YaHei', 'Microsoft YaHei UI', 'SimSun', 'NSimSun', ...
                'SimHei', 'KaiTi', 'FangSong', 'DengXian', 'YouYuan', ...
                '微软雅黑', '宋体', '黑体', '楷体', '仿宋', '等线', '幼圆'};
            try
                sysFonts = cellstr(listfonts);
            catch
                sysFonts = {};
            end
            fonts = unique([preferred(:); sysFonts(:)], 'stable');
            fonts = fonts(~cellfun(@isempty, fonts));
        end

        function chooseColor(app, btn, titleText)
            try
                currentColor = btn.UserData;
                if isempty(currentColor), currentColor = btn.BackgroundColor; end
                newColor = app.showColorDialog(btn, currentColor, titleText);
                if isnumeric(newColor) && numel(newColor) == 3
                    app.setColorButton(btn, newColor);
                    app.addRecentColor(newColor);
                    app.UpdateRealTimeSettings();
                end
                app.restoreMainWindow();
            catch ME
                app.handleRuntimeError(ME, titleText);
            end
        end

        function restoreMainWindow(app)
            try
                if isvalid(app) && isvalid(app.UIFigure)
                    app.UIFigure.Visible = 'on';
                    app.UIFigure.WindowState = 'normal';
                    figure(app.UIFigure);
                    drawnow limitrate;
                end
            catch
            end
        end

        function addRecentColor(app, rgb)
            rgb = max(0, min(1, double(rgb(:)')));
            if numel(rgb) ~= 3, return; end
            colors = [rgb; app.RecentColors];
            keep = true(size(colors, 1), 1);
            for i = 2:size(colors, 1)
                keep(i) = all(vecnorm(colors(1:i-1, :) - colors(i, :), 2, 2) > 1e-6);
            end
            colors = colors(keep, :);
            app.RecentColors = colors(1:min(8, size(colors, 1)), :);
        end

        function rgb = showColorDialog(app, targetButton, currentColor, titleText)
            rgb = [];
            originalColor = max(0, min(1, double(currentColor(:)')));
            dlg = uifigure('Name', titleText, 'Position', [520 210 440 410], 'WindowStyle', 'modal', 'Resize', 'off');
            dlg.CloseRequestFcn = @(src, event) closeColorDialog(false);
            main = uigridlayout(dlg, [5 1]);
            main.RowHeight = {24, 126, 62, 86, 52};
            main.RowSpacing = 8;
            main.Padding = [12 10 12 10];
            uilabel(main, 'Text', titleText, 'FontWeight', 'bold');

            standardPanel = uipanel(main, 'Title', '标准颜色');
            standardGrid = uigridlayout(standardPanel, [3 8]);
            standardGrid.Padding = [8 8 8 8];
            standardGrid.RowHeight = repmat({'1x'}, 1, 3);
            standardGrid.ColumnWidth = repmat({'1x'}, 1, 8);
            standardColors = [ ...
                0.000 0.447 0.741; 0.850 0.325 0.098; 0.929 0.694 0.125; 0.494 0.184 0.556; ...
                0.466 0.674 0.188; 0.301 0.745 0.933; 0.635 0.078 0.184; 1.000 0.000 0.000; ...
                0.000 1.000 0.000; 0.000 0.000 1.000; 1.000 1.000 0.000; 1.000 0.000 1.000; ...
                0.000 1.000 1.000; 0.000 0.000 0.000; 0.250 0.250 0.250; 0.500 0.500 0.500; ...
                0.750 0.750 0.750; 1.000 1.000 1.000; 0.900 0.100 0.100; 0.100 0.600 0.900; ...
                0.100 0.700 0.300; 0.900 0.500 0.100; 0.500 0.200 0.800; 0.600 0.300 0.100];
            selected = originalColor;
            for i = 1:size(standardColors, 1)
                c = standardColors(i, :);
                b = uibutton(standardGrid, 'push', 'Text', '', 'BackgroundColor', c);
                b.ButtonPushedFcn = @(src, event) setSelected(src.BackgroundColor);
            end

            recentPanel = uipanel(main, 'Title', '最近使用');
            recentGrid = uigridlayout(recentPanel, [1 8]);
            recentGrid.Padding = [8 8 8 8];
            recentGrid.ColumnWidth = repmat({'1x'}, 1, 8);
            if isempty(app.RecentColors)
                recentColors = repmat([1 1 1], 8, 1);
            else
                recentColors = [app.RecentColors; repmat([1 1 1], max(0, 8 - size(app.RecentColors, 1)), 1)];
            end
            for i = 1:8
                c = recentColors(i, :);
                b = uibutton(recentGrid, 'push', 'Text', '', 'BackgroundColor', c);
                if i <= size(app.RecentColors, 1)
                    b.ButtonPushedFcn = @(src, event) setSelected(src.BackgroundColor);
                else
                    b.Enable = 'off';
                end
            end

            rgbPanel = uipanel(main, 'Title', 'RGB (0-255)');
            rgbGrid = uigridlayout(rgbPanel, [1 6]);
            rgbGrid.ColumnWidth = {20, '1x', 20, '1x', 20, '1x'};
            rgbGrid.Padding = [8 8 8 8];
            uilabel(rgbGrid, 'Text', 'R');
            rEdit = uieditfield(rgbGrid, 'numeric', 'Limits', [0 255], 'RoundFractionalValues', 'on', 'Value', round(selected(1)*255));
            uilabel(rgbGrid, 'Text', 'G');
            gEdit = uieditfield(rgbGrid, 'numeric', 'Limits', [0 255], 'RoundFractionalValues', 'on', 'Value', round(selected(2)*255));
            uilabel(rgbGrid, 'Text', 'B');
            bEdit = uieditfield(rgbGrid, 'numeric', 'Limits', [0 255], 'RoundFractionalValues', 'on', 'Value', round(selected(3)*255));
            rEdit.ValueChangedFcn = @(src, event) setSelectedFromEdits();
            gEdit.ValueChangedFcn = @(src, event) setSelectedFromEdits();
            bEdit.ValueChangedFcn = @(src, event) setSelectedFromEdits();

            btnGrid = uigridlayout(main, [1 2]);
            btnGrid.ColumnWidth = {'1x', '1x'};
            btnGrid.ColumnSpacing = 10;
            btnGrid.Padding = [0 5 0 5];
            okBtn = uibutton(btnGrid, 'push', 'Text', '确定');
            cancelBtn = uibutton(btnGrid, 'push', 'Text', '取消');
            okBtn.ButtonPushedFcn = @(src, event) closeColorDialog(true);
            cancelBtn.ButtonPushedFcn = @(src, event) closeColorDialog(false);
            uiwait(dlg);
            if isvalid(dlg)
                if isfield(dlg.UserData, 'Accepted') && dlg.UserData.Accepted
                    rgb = dlg.UserData.Color;
                else
                    app.setColorButton(targetButton, originalColor);
                    app.UpdateRealTimeSettings();
                end
                delete(dlg);
            end

            function setSelected(c)
                selected = max(0, min(1, double(c(:)')));
                rEdit.Value = round(selected(1)*255);
                gEdit.Value = round(selected(2)*255);
                bEdit.Value = round(selected(3)*255);
                app.setColorButton(targetButton, selected);
                app.UpdateRealTimeSettings();
                drawnow limitrate;
            end

            function setSelectedFromEdits()
                setSelected([rEdit.Value, gEdit.Value, bEdit.Value] / 255);
            end

            function closeColorDialog(accepted)
                if isvalid(dlg)
                    dlg.UserData = struct('Accepted', accepted, 'Color', selected);
                    uiresume(dlg);
                end
            end
        end

        function setColorButton(~, btn, rgb)
            rgb = max(0, min(1, double(rgb(:)')));
            if numel(rgb) ~= 3, rgb = [0 0 0]; end
            btn.UserData = rgb;
            btn.BackgroundColor = rgb;
            if mean(rgb) < 0.45
                btn.FontColor = [1 1 1];
            else
                btn.FontColor = [0 0 0];
            end
            btn.Text = 'RGB';
            try
                btn.Tooltip = sprintf('RGB %.2f, %.2f, %.2f', rgb(1), rgb(2), rgb(3));
            catch
            end
        end

        function rgb = getButtonColor(~, btn, fallback)
            rgb = fallback;
            try
                if ~isempty(btn.UserData) && isnumeric(btn.UserData) && numel(btn.UserData) == 3
                    rgb = double(btn.UserData(:)');
                end
            catch
            end
        end

        function syncAxisStyleEnable(app, varargin)
            app.setAxisStyleControlsEnabled(app.XStyleOverrideChk.Value, app.XAxisColorBtn, app.XTitleColorBtn, app.XAxisFontDrop, app.XAxisFontSizeEdit);
            app.setAxisStyleControlsEnabled(app.YLeftStyleOverrideChk.Value, app.YLeftAxisColorBtn, app.YLeftTitleColorBtn, app.YLeftAxisFontDrop, app.YLeftAxisFontSizeEdit);
            app.setAxisStyleControlsEnabled(app.YRightStyleOverrideChk.Value, app.YRightAxisColorBtn, app.YRightTitleColorBtn, app.YRightAxisFontDrop, app.YRightAxisFontSizeEdit);
            app.UpdateRealTimeSettings();
        end

        function setAxisStyleControlsEnabled(~, enabled, axisColorBtn, titleColorBtn, fontDrop, fontSizeEdit)
            state = fastif(enabled, 'on', 'off');
            axisColorBtn.Enable = state;
            titleColorBtn.Enable = state;
            fontDrop.Enable = state;
            fontSizeEdit.Enable = state;
        end

        function style = getAxisStyle(app, axisName)
            style.FontName = app.FontDrop.Value;
            style.FontSize = app.FontSizeEdit.Value;
            style.AxisColor = [0 0 0];
            style.TitleColor = [0 0 0];
            switch axisName
                case 'X'
                    if app.XStyleOverrideChk.Value
                        style.FontName = app.XAxisFontDrop.Value;
                        style.FontSize = app.XAxisFontSizeEdit.Value;
                        style.AxisColor = app.getButtonColor(app.XAxisColorBtn, style.AxisColor);
                        style.TitleColor = app.getButtonColor(app.XTitleColorBtn, style.TitleColor);
                    end
                case 'YLeft'
                    if app.YLeftStyleOverrideChk.Value
                        style.FontName = app.YLeftAxisFontDrop.Value;
                        style.FontSize = app.YLeftAxisFontSizeEdit.Value;
                        style.AxisColor = app.getButtonColor(app.YLeftAxisColorBtn, style.AxisColor);
                        style.TitleColor = app.getButtonColor(app.YLeftTitleColorBtn, style.TitleColor);
                    end
                case 'YRight'
                    style.AxisColor = [0.15 0.15 0.15];
                    style.TitleColor = [0.15 0.15 0.15];
                    if app.YRightStyleOverrideChk.Value
                        style.FontName = app.YRightAxisFontDrop.Value;
                        style.FontSize = app.YRightAxisFontSizeEdit.Value;
                        style.AxisColor = app.getButtonColor(app.YRightAxisColorBtn, style.AxisColor);
                        style.TitleColor = app.getButtonColor(app.YRightTitleColorBtn, style.TitleColor);
                    end
            end
        end

        function applyAxisTextStyle(app, ax, axisName, scale)
            if nargin < 4, scale = 1; end
            st = app.getAxisStyle(axisName);
            switch axisName
                case 'X'
                    ax.XColor = st.AxisColor;
                    ax.XLabel.Color = st.TitleColor;
                    ax.XLabel.FontName = st.FontName;
                    ax.XLabel.FontSize = st.FontSize * scale;
                    try ax.XAxis.FontName = st.FontName; ax.XAxis.FontSize = st.FontSize * scale; catch, end
                case 'YLeft'
                    yyaxis(ax, 'left');
                    ax.YColor = st.AxisColor;
                    ax.YLabel.Color = st.TitleColor;
                    ax.YLabel.FontName = st.FontName;
                    ax.YLabel.FontSize = st.FontSize * scale;
                    try ax.YAxis(1).FontName = st.FontName; ax.YAxis(1).FontSize = st.FontSize * scale; catch, end
                case 'YRight'
                    yyaxis(ax, 'right');
                    ax.YColor = st.AxisColor;
                    ax.YLabel.Color = st.TitleColor;
                    ax.YLabel.FontName = st.FontName;
                    ax.YLabel.FontSize = st.FontSize * scale;
                    try ax.YAxis(2).FontName = st.FontName; ax.YAxis(2).FontSize = st.FontSize * scale; catch, end
            end
        end

        function drawFrameBorder(app, ax, scale)
            if nargin < 3, scale = 1; end
            if ~isvalid(ax), return; end
            try delete(findall(ax, 'Tag', 'BorderLine')); catch, end
            try yyaxis(ax, 'left'); catch, end
            holdState = ishold(ax);
            hold(ax, 'on');
            ax.Box = 'off';
            ax.XAxisLocation = 'bottom';
            xl = xlim(ax);
            yl = ylim(ax);
            lw_ax = app.AxisWidthEdit.Value * scale;
            plot(ax, [xl(1), xl(2), xl(2), xl(1), xl(1)], [yl(1), yl(1), yl(2), yl(2), yl(1)], ...
                'k-', 'LineWidth', lw_ax, 'Tag', 'BorderLine', 'HandleVisibility', 'off', 'Clipping', 'off');
            if ~holdState
                hold(ax, 'off');
            end
        end

        function items = getLegendShapeItems(~)
            items = {'仅线', '仅点', '线+圆点', '线+方块', '线+菱形', '线+上三角', '线+下三角', '线+五角星', '线+十字', '线+加号'};
        end

        function [lineStyle, marker] = getLegendShapeStyle(app)
            if isempty(app.LegendShapeDrop) || ~isvalid(app.LegendShapeDrop)
                val = '仅线';
            else
                val = app.LegendShapeDrop.Value;
            end
            switch val
                case '仅点'
                    lineStyle = 'none'; marker = 'o';
                case '线+圆点'
                    lineStyle = '-'; marker = 'o';
                case '线+方块'
                    lineStyle = '-'; marker = 's';
                case '线+菱形'
                    lineStyle = '-'; marker = 'd';
                case '线+上三角'
                    lineStyle = '-'; marker = '^';
                case '线+下三角'
                    lineStyle = '-'; marker = 'v';
                case '线+五角星'
                    lineStyle = '-'; marker = 'p';
                case '线+十字'
                    lineStyle = '-'; marker = 'x';
                case '线+加号'
                    lineStyle = '-'; marker = '+';
                otherwise
                    lineStyle = '-'; marker = 'none';
            end
        end

        function markerIdx = getSparseMarkerIndices(~, n)
            n = max(0, round(n));
            if n <= 0
                markerIdx = [];
                return;
            end
            maxMarkers = 28;
            if n <= maxMarkers
                markerIdx = 1:n;
            else
                markerIdx = unique(round(linspace(1, n, maxMarkers)));
            end
        end

        function applySparseMarkerIndices(app, hLines)
            for i = 1:numel(hLines)
                if isgraphics(hLines(i))
                    try
                        xData = hLines(i).XData;
                        validCount = nnz(~isnan(xData));
                        if strcmp(hLines(i).Marker, 'none') || validCount <= 0
                            hLines(i).MarkerIndices = [];
                            continue;
                        end
                        hLines(i).MarkerIndices = app.getSparseMarkerIndices(validCount);
                    catch
                    end
                end
            end
        end

        function applyLineAppearance(app, hLines, colors, lw, markerScale)
            if nargin < 5, markerScale = 1; end
            [lineStyle, marker] = app.getLegendShapeStyle();
            markerSize = 6;
            try markerSize = max(1, app.MarkerSizeEdit.Value) * markerScale; catch, end
            for i = 1:numel(hLines)
                if isgraphics(hLines(i))
                    set(hLines(i), 'LineWidth', lw, 'Color', colors(i,:), ...
                        'LineStyle', lineStyle, 'Marker', marker, 'MarkerSize', markerSize, ...
                        'MarkerEdgeColor', colors(i,:), 'MarkerFaceColor', fastif(strcmp(marker, 'none') || any(strcmp(marker, {'x','+'})), 'none', colors(i,:)));
                end
            end
            app.applySparseMarkerIndices(hLines);
        end

        function applyLegendBoxStyle(app, lgd)
            if app.LgdBgChk.Value
                lgd.Color = 'w';
                lgd.Box = 'on';
                if app.LgdBorderChk.Value
                    lgd.EdgeColor = [0.15 0.15 0.15];
                else
                    lgd.EdgeColor = [1 1 1];
                end
            else
                lgd.Color = 'none';
                if app.LgdBorderChk.Value
                    lgd.Box = 'on';
                    lgd.EdgeColor = [0.15 0.15 0.15];
                else
                    lgd.Box = 'off';
                end
            end
        end

        function state = captureLegendState(~, ax)
            state = [];
            try
                lgd = ax.Legend;
                if isempty(lgd) || ~isvalid(lgd)
                    return;
                end
                state.String = lgd.String;
                state.NumColumns = lgd.NumColumns;
                state.Location = lgd.Location;
                state.Units = lgd.Units;
                state.Position = lgd.Position;
                state.ItemTokenSize = lgd.ItemTokenSize;
                state.Visible = lgd.Visible;
            catch
                state = [];
            end
        end

        function restoreLegendState(app, ax, state)
            if isempty(state)
                return;
            end
            try
                lgd = ax.Legend;
                if isempty(lgd) || ~isvalid(lgd)
                    return;
                end
                if numel(lgd.String) == numel(state.String)
                    lgd.String = state.String;
                end
                lgd.NumColumns = state.NumColumns;
                lgd.ItemTokenSize = state.ItemTokenSize;
                lgd.Visible = state.Visible;
                app.applyLegendBoxStyle(lgd);
                drawnow limitrate;
                lgd.Units = state.Units;
                lgd.Location = 'none';
                lgd.Position = state.Position;
            catch
            end
        end

        function LoadBtnPushed(app, varargin)
            [file, path] = uigetfile('*.csv', '选择 CSV 数据文件');
            app.restoreMainWindow();
            if isequal(file, 0), return; end
            
            filename = fullfile(path, file);
            opts = detectImportOptions(filename);
            app.Headers = opts.VariableNames;
            app.RawData = readmatrix(filename);
            
            app.XMinEdit.Value = 0; app.XMaxEdit.Value = 0;
            app.YMinEdit.Value = 0; app.YMaxEdit.Value = 0; 
            app.YRightMinEdit.Value = 0; app.YRightMaxEdit.Value = 0;
            app.XTickSpaceEdit.Value = 0; app.YTickSpaceEdit.Value = 0;
            app.YRightTickSpaceEdit.Value = 0;
            app.XFormatDrop.Value = '常规整数'; app.XDecEdit.Value = 0;
            app.YFormatDrop.Value = '常规整数'; app.YDecEdit.Value = 0;
            app.YRightFormatDrop.Value = '常规整数'; app.YRightDecEdit.Value = 0;
            
            num_vars = length(app.Headers);
            tableData = cell(num_vars, 4);
            for i = 1:num_vars
                raw_name = app.Headers{i};
                idx = strfind(raw_name, 'hight');
                if ~isempty(idx), clean_name = strrep(raw_name(idx:end), '_', '-');
                else, clean_name = strrep(raw_name, '_', '-'); end
                
                tableData{i, 1} = clean_name; 
                tableData{i, 2} = false; 
                tableData{i, 3} = false;
                tableData{i, 4} = false;
            end
            app.DataTable.Data = tableData;
            
            app.RecomputeDataAndLimits(); 
            app.ResetBtnPushed();
        end

        function ReplaceBtnPushed(app, varargin)
            find_str = app.FindEdit.Value; rep_str = app.ReplaceEdit.Value;
            if isempty(find_str), uialert(app.UIFigure, '请输入要查找的字符！', '提示'); app.restoreMainWindow(); return; end
            tData = app.DataTable.Data; if isempty(tData), return; end
            count = 0;
            for i = 1:size(tData, 1)
                old_name = tData{i, 1};
                if ischar(old_name) || isstring(old_name)
                    new_name = strrep(old_name, find_str, rep_str);
                    if ~strcmp(old_name, new_name)
                        tData{i, 1} = new_name; count = count + 1;
                    end
                end
            end
            app.DataTable.Data = tData;
            if count > 0, app.RecomputeDataAndLimits(); uialert(app.UIFigure, sprintf('成功替换了 %d 个名称！已自动刷新。', count), '替换完成', 'Icon', 'success');
            else, uialert(app.UIFigure, '未找到可替换的字符。', '提示', 'Icon', 'info'); end
            app.restoreMainWindow();
        end

        function DataTableEdited(app, varargin)
            tData = app.DataTable.Data;
            if isempty(tData), return; end
            if size(tData, 2) < 4
                tData(:, 4) = {false};
            end
            if nargin >= 3
                event = varargin{2};
                if isprop(event, 'Indices') && ~isempty(event.Indices)
                    row = event.Indices(1);
                    col = event.Indices(2);
                    if col == 2 && logical(tData{row, 2})
                        tData(:, 2) = {false};
                        tData{row, 2} = true;
                        tData{row, 3} = false;
                        tData{row, 4} = false;
                    elseif col == 3 && logical(tData{row, 3})
                        tData{row, 2} = false;
                        tData{row, 4} = false;
                    elseif col == 4 && logical(tData{row, 4})
                        tData{row, 2} = false;
                        tData{row, 3} = false;
                    end
                end
            else
                xRows = find(cell2mat(tData(:, 2)));
                if numel(xRows) > 1
                    keepRow = xRows(end);
                    tData(:, 2) = {false};
                    tData{keepRow, 2} = true;
                end
                for row = 1:size(tData, 1)
                    if logical(tData{row, 3}) && logical(tData{row, 4})
                        tData{row, 4} = false;
                    end
                end
            end
            app.DataTable.Data = tData;
            app.RecomputeDataAndLimits();
        end

        function SelectAllYPushed(app, varargin)
            tData = app.DataTable.Data; if isempty(tData), return; end
            if size(tData, 2) < 4, tData(:, 4) = {false}; end
            tData(:, 3) = {true}; tData(:, 4) = {false};
            xRows = find(cell2mat(tData(:, 2)));
            for k = 1:numel(xRows), tData{xRows(k), 3} = false; end
            app.DataTable.Data = tData; app.RecomputeDataAndLimits();
        end

        function ClearYPushed(app, varargin)
            tData = app.DataTable.Data; if isempty(tData), return; end
            if size(tData, 2) < 4, tData(:, 4) = {false}; end
            tData(:, 3) = {false}; tData(:, 4) = {false};
            app.DataTable.Data = tData; app.RecomputeDataAndLimits();
        end

        function LgdXSliderChanging(app, event), app.LgdXEdit.Value = event.Value; app.UpdateLegendPosOnly(event.Value, app.LgdYEdit.Value); end
        function LgdYSliderChanging(app, event), app.LgdYEdit.Value = event.Value; app.UpdateLegendPosOnly(app.LgdXEdit.Value, event.Value); end
        function LgdXEditChanged(app, varargin)
            bounds = app.LgdXEdit.Limits;
            val = min(max(app.LgdXEdit.Value, bounds(1)), bounds(2)); 
            app.LgdXEdit.Value = val; app.LgdXSlider.Value = val; 
            app.UpdateLegendPosOnly(val, app.LgdYEdit.Value); 
        end
        function LgdYEditChanged(app, varargin)
            bounds = app.LgdYEdit.Limits;
            val = min(max(app.LgdYEdit.Value, bounds(1)), bounds(2)); 
            app.LgdYEdit.Value = val; app.LgdYSlider.Value = val; 
            app.UpdateLegendPosOnly(app.LgdXEdit.Value, val); 
        end

        function UpdateLegendPosOnly(app, x_val, y_val)
            if ~isvalid(app) || ~isvalid(app.UIAxes), return; end
            if ~isempty(app.UIAxes.Legend)
                lgd = app.UIAxes.Legend; 
                
                old_ax_units = app.UIAxes.Units;
                app.UIAxes.Units = 'normalized';
                ax_pos = app.UIAxes.Position;
                app.UIAxes.Units = old_ax_units;
                
                old_lgd_units = lgd.Units;
                lgd.Units = 'normalized';
                lgd_pos = lgd.Position;
                
                nx = ax_pos(1) + x_val * max(0.001, ax_pos(3) - lgd_pos(3));
                ny = ax_pos(2) + y_val * max(0.001, ax_pos(4) - lgd_pos(4));
                
                lgd.Location = 'none'; 
                lgd.Position(1:2) = [nx, ny];
                lgd.Units = old_lgd_units;
                
                drawnow limitrate;
            end
        end

        function saveSettings(app)
            try
                s.ColorDrop = app.ColorDrop.Value; s.FontDrop = app.FontDrop.Value;
                s.XFormatDrop = app.XFormatDrop.Value; s.XDecEdit = app.XDecEdit.Value;
                s.YFormatDrop = app.YFormatDrop.Value; s.YDecEdit = app.YDecEdit.Value;
                s.YRightFormatDrop = app.YRightFormatDrop.Value; s.YRightDecEdit = app.YRightDecEdit.Value;
                s.AxisWidthEdit = app.AxisWidthEdit.Value; s.FontSizeEdit = app.FontSizeEdit.Value;
                s.LineWidthEdit = app.LineWidthEdit.Value; s.LgdFontEdit = app.LgdFontEdit.Value;
                s.XTickSpaceEdit = app.XTickSpaceEdit.Value; s.YTickSpaceEdit = app.YTickSpaceEdit.Value;
                s.YRightTickSpaceEdit = app.YRightTickSpaceEdit.Value;
                s.LgdXSlider = app.LgdXSlider.Value; s.LgdYSlider = app.LgdYSlider.Value;
                s.FontBoldChk = app.FontBoldChk.Value; 
                s.TickOutChk = app.TickOutChk.Value; 
                s.LgdBgChk = app.LgdBgChk.Value; s.LgdBorderChk = app.LgdBorderChk.Value;
                s.GridLineChk = app.GridLineChk.Value; 
                s.LgdVisibleChk = app.LgdVisibleChk.Value; s.LgdColsEdit = app.LgdColsEdit.Value; 
                s.IntervalEdit = app.IntervalEdit.Value; s.WidthEdit = app.WidthEdit.Value; 
                s.HeightEdit = app.HeightEdit.Value; s.DPIEdit = app.DPIEdit.Value;
                s.XLabelEdit = app.XLabelEdit.Value; s.YLabelEdit = app.YLabelEdit.Value; s.YRightLabelEdit = app.YRightLabelEdit.Value;
                s.AxisStyle.XOverride = app.XStyleOverrideChk.Value;
                s.AxisStyle.YLeftOverride = app.YLeftStyleOverrideChk.Value;
                s.AxisStyle.YRightOverride = app.YRightStyleOverrideChk.Value;
                s.AxisStyle.XAxisColor = app.getButtonColor(app.XAxisColorBtn, [0 0 0]);
                s.AxisStyle.XTitleColor = app.getButtonColor(app.XTitleColorBtn, [0 0 0]);
                s.AxisStyle.YLeftAxisColor = app.getButtonColor(app.YLeftAxisColorBtn, [0 0 0]);
                s.AxisStyle.YLeftTitleColor = app.getButtonColor(app.YLeftTitleColorBtn, [0 0 0]);
                s.AxisStyle.YRightAxisColor = app.getButtonColor(app.YRightAxisColorBtn, [0.15 0.15 0.15]);
                s.AxisStyle.YRightTitleColor = app.getButtonColor(app.YRightTitleColorBtn, [0.15 0.15 0.15]);
                s.AxisStyle.XFont = app.XAxisFontDrop.Value; s.AxisStyle.XFontSize = app.XAxisFontSizeEdit.Value;
                s.AxisStyle.YLeftFont = app.YLeftAxisFontDrop.Value; s.AxisStyle.YLeftFontSize = app.YLeftAxisFontSizeEdit.Value;
                s.AxisStyle.YRightFont = app.YRightAxisFontDrop.Value; s.AxisStyle.YRightFontSize = app.YRightAxisFontSizeEdit.Value;
                s.LegendShapeDrop = app.LegendShapeDrop.Value;
                s.MarkerSizeEdit = app.MarkerSizeEdit.Value;
                s.RecentColors = app.RecentColors;
                s.Format = app.ExportFormatDrop.Value;
                setpref('LineAnimationApp', 'Settings', s);
            catch
            end
        end

        function loadSettings(app)
            if ispref('LineAnimationApp', 'Settings')
                s = getpref('LineAnimationApp', 'Settings');
                try
                    if isfield(s, 'ColorDrop') && any(strcmp(app.ColorDrop.Items, s.ColorDrop)), app.ColorDrop.Value = s.ColorDrop; end
                    if isfield(s, 'FontDrop') && any(strcmp(app.FontDrop.Items, s.FontDrop)), app.FontDrop.Value = s.FontDrop; end
                catch
                end
                try app.XFormatDrop.Value = s.XFormatDrop; app.XDecEdit.Value = s.XDecEdit; catch, end
                try app.YFormatDrop.Value = s.YFormatDrop; app.YDecEdit.Value = s.YDecEdit; catch, end
                try app.YRightFormatDrop.Value = s.YRightFormatDrop; app.YRightDecEdit.Value = s.YRightDecEdit; catch, end
                try app.AxisWidthEdit.Value = s.AxisWidthEdit; app.FontSizeEdit.Value = s.FontSizeEdit; catch, end
                try app.LineWidthEdit.Value = s.LineWidthEdit; app.LgdFontEdit.Value = s.LgdFontEdit; catch, end
                try app.XTickSpaceEdit.Value = s.XTickSpaceEdit; app.YTickSpaceEdit.Value = s.YTickSpaceEdit; catch, end
                try app.YRightTickSpaceEdit.Value = s.YRightTickSpaceEdit; catch, end
                try app.LgdXSlider.Value = s.LgdXSlider; app.LgdXEdit.Value = s.LgdXSlider; catch, end
                try app.LgdYSlider.Value = s.LgdYSlider; app.LgdYEdit.Value = s.LgdYSlider; catch, end
                try app.FontBoldChk.Value = s.FontBoldChk; catch, end
                try app.TickOutChk.Value = s.TickOutChk; catch, end 
                try app.LgdBgChk.Value = s.LgdBgChk; app.LgdBorderChk.Value = s.LgdBorderChk; catch, end
                try app.GridLineChk.Value = s.GridLineChk; catch, end
                try app.LgdVisibleChk.Value = s.LgdVisibleChk; app.LgdColsEdit.Value = s.LgdColsEdit; catch, end 
                try app.IntervalEdit.Value = s.IntervalEdit; app.WidthEdit.Value = s.WidthEdit; catch, end
                try app.HeightEdit.Value = s.HeightEdit; app.DPIEdit.Value = s.DPIEdit; catch, end
                try app.XLabelEdit.Value = s.XLabelEdit; app.YLabelEdit.Value = s.YLabelEdit; catch, end
                try app.YRightLabelEdit.Value = s.YRightLabelEdit; catch, end
                try
                    if isfield(s, 'LegendShapeDrop') && any(strcmp(app.LegendShapeDrop.Items, s.LegendShapeDrop)), app.LegendShapeDrop.Value = s.LegendShapeDrop; end
                    if isfield(s, 'MarkerSizeEdit'), app.MarkerSizeEdit.Value = s.MarkerSizeEdit; end
                    if isfield(s, 'RecentColors') && isnumeric(s.RecentColors), app.RecentColors = s.RecentColors; end
                catch
                end
                try
                    if isfield(s, 'AxisStyle')
                        app.XStyleOverrideChk.Value = s.AxisStyle.XOverride;
                        app.YLeftStyleOverrideChk.Value = s.AxisStyle.YLeftOverride;
                        app.YRightStyleOverrideChk.Value = s.AxisStyle.YRightOverride;
                        app.setColorButton(app.XAxisColorBtn, s.AxisStyle.XAxisColor);
                        app.setColorButton(app.XTitleColorBtn, s.AxisStyle.XTitleColor);
                        app.setColorButton(app.YLeftAxisColorBtn, s.AxisStyle.YLeftAxisColor);
                        app.setColorButton(app.YLeftTitleColorBtn, s.AxisStyle.YLeftTitleColor);
                        app.setColorButton(app.YRightAxisColorBtn, s.AxisStyle.YRightAxisColor);
                        app.setColorButton(app.YRightTitleColorBtn, s.AxisStyle.YRightTitleColor);
                        if any(strcmp(app.XAxisFontDrop.Items, s.AxisStyle.XFont)), app.XAxisFontDrop.Value = s.AxisStyle.XFont; end
                        if any(strcmp(app.YLeftAxisFontDrop.Items, s.AxisStyle.YLeftFont)), app.YLeftAxisFontDrop.Value = s.AxisStyle.YLeftFont; end
                        if any(strcmp(app.YRightAxisFontDrop.Items, s.AxisStyle.YRightFont)), app.YRightAxisFontDrop.Value = s.AxisStyle.YRightFont; end
                        app.XAxisFontSizeEdit.Value = s.AxisStyle.XFontSize;
                        app.YLeftAxisFontSizeEdit.Value = s.AxisStyle.YLeftFontSize;
                        app.YRightAxisFontSizeEdit.Value = s.AxisStyle.YRightFontSize;
                    end
                catch
                end
                try
                    if isfield(s, 'Format') && any(strcmp(app.ExportFormatDrop.ItemsData, s.Format))
                        app.ExportFormatDrop.Value = s.Format;
                    end
                catch
                end
            end
            app.syncAxisStyleEnable();
            app.UpdateAxesSize();
        end

        function AppCloseRequest(app, varargin), app.IsPlaying = false; drawnow limitrate; app.saveSettings(); delete(app.UIFigure); end
        
        function UpdateAxesSize(app, varargin)
            if ~isvalid(app) || ~isvalid(app.AxesWrapper) || ~isvalid(app.UIAxes) || ~isvalid(app.PlotArea), return; end
            w = app.WidthEdit.Value; h = app.HeightEdit.Value;
            pw = app.AxesWrapper.Position(3); ph = app.AxesWrapper.Position(4);
            if isnan(pw) || pw <= 0, pw = 800; end; if isnan(ph) || ph <= 0, ph = 500; end
            
            ax_x = max(10, (pw - w)/2); 
            ax_y = max(10, (ph - h)/2);
            app.PlotArea.Position = [ax_x, ax_y, w, h];
            
            app.UpdateRealTimeSettings();
        end

        function RecomputeDataAndLimits(app)
            tData = app.DataTable.Data; if isempty(tData), return; end
            if size(tData, 2) < 4, tData(:, 4) = {false}; app.DataTable.Data = tData; end
            isX = cell2mat(tData(:, 2)); isYLeft = cell2mat(tData(:, 3)); isYRight = cell2mat(tData(:, 4));
            x_idx = find(isX, 1); y_left_idxs = find(isYLeft)'; y_right_idxs = find(isYRight)';
            
            if isempty(x_idx) || (isempty(y_left_idxs) && isempty(y_right_idxs))
                cla(app.UIAxes); legend(app.UIAxes, 'off'); app.H_Lines = []; app.H_LinesLeft = []; app.H_LinesRight = [];
                app.X_Data_Plot = []; app.Y_Data_Plot = []; app.Y_Left_Data_Plot = []; app.Y_Right_Data_Plot = [];
                app.UpdateRealTimeSettings(); return;
            end
            
            app.X_Data_Plot = app.RawData(:, x_idx);
            y_left_idxs = app.sortColumnsByHeaderNumber(y_left_idxs);
            y_right_idxs = app.sortColumnsByHeaderNumber(y_right_idxs);
            app.Y_Left_Data_Plot = app.RawData(:, y_left_idxs);
            app.Y_Right_Data_Plot = app.RawData(:, y_right_idxs);
            app.Y_Data_Plot = [app.Y_Left_Data_Plot, app.Y_Right_Data_Plot];
            app.LegendLabelsLeft = tData(y_left_idxs, 1);
            app.LegendLabelsRight = tData(y_right_idxs, 1);
            app.LegendLabels = [app.LegendLabelsLeft; app.LegendLabelsRight]; 
            app.HasRightAxis = ~isempty(app.Y_Right_Data_Plot);
            
            x_min = min(app.X_Data_Plot); x_max = max(app.X_Data_Plot); 
            if x_max <= x_min, x_max = x_min + 1; end
            if ~isempty(app.Y_Left_Data_Plot)
                y_min = min(app.Y_Left_Data_Plot(:)); if y_min > 0, y_min = 0; end 
                y_max = max(app.Y_Left_Data_Plot(:)); if y_max <= y_min, y_max = y_min + 1; end
            else
                y_min = 0; y_max = 1;
            end
            if ~isempty(app.Y_Right_Data_Plot)
                yr_min = min(app.Y_Right_Data_Plot(:)); if yr_min > 0, yr_min = 0; end
                yr_max = max(app.Y_Right_Data_Plot(:)); if yr_max <= yr_min, yr_max = yr_min + 1; end
            else
                yr_min = 0; yr_max = 1;
            end
            
            if app.XMinEdit.Value == 0 && app.XMaxEdit.Value == 0
                app.XMinEdit.Value = x_min; app.XMaxEdit.Value = x_max;
            end
            
            if app.YMinEdit.Value == 0 && app.YMaxEdit.Value == 0
                app.YMinEdit.Value = y_min; app.YMaxEdit.Value = y_max;
            end

            if app.YRightMinEdit.Value == 0 && app.YRightMaxEdit.Value == 0
                app.YRightMinEdit.Value = yr_min; app.YRightMaxEdit.Value = yr_max;
            end
            
            app.PlotStaticFull();
        end

        function sortedIdxs = sortColumnsByHeaderNumber(app, idxs)
            if isempty(idxs)
                sortedIdxs = idxs;
                return;
            end
            selected_raw = app.Headers(idxs);
            numeric_vals = zeros(1, length(idxs));
            for i = 1:length(idxs)
                num_str = regexp(selected_raw{i}, '\d+', 'match'); 
                if ~isempty(num_str), numeric_vals(i) = str2double(num_str{1}); 
                else, numeric_vals(i) = inf; end
            end
            [~, sort_idx] = sort(numeric_vals);
            sortedIdxs = idxs(sort_idx);
        end

        function PlotStaticFull(app, preserveLegend)
            if nargin < 2, preserveLegend = false; end
            if isempty(app.X_Data_Plot) || (isempty(app.Y_Left_Data_Plot) && isempty(app.Y_Right_Data_Plot)), return; end
            ax = app.UIAxes;
            legendState = [];
            if preserveLegend
                legendState = app.captureLegendState(ax);
            end
            legend(ax, 'off');
            yyaxis(ax, 'left'); cla(ax);
            yyaxis(ax, 'right'); cla(ax);
            yyaxis(ax, 'left'); hold(ax, 'on');
            num_left = size(app.Y_Left_Data_Plot, 2);
            num_right = size(app.Y_Right_Data_Plot, 2);
            num_lines = num_left + num_right;
            if num_lines == 0, return; end
            colors = app.getColorMap(app.ColorDrop.Value, num_lines);
            
            app.H_LinesLeft = gobjects(1, num_left);
            app.H_LinesRight = gobjects(1, num_right);
            lw = app.LineWidthEdit.Value;
            yyaxis(ax, 'left');
            for i = 1:num_left
                app.H_LinesLeft(i) = plot(ax, app.X_Data_Plot, app.Y_Left_Data_Plot(:, i), 'LineWidth', lw, 'Color', colors(i,:));
            end
            yyaxis(ax, 'right');
            hold(ax, 'on');
            for i = 1:num_right
                app.H_LinesRight(i) = plot(ax, app.X_Data_Plot, app.Y_Right_Data_Plot(:, i), 'LineWidth', lw, 'Color', colors(num_left + i,:));
            end
            app.H_Lines = [app.H_LinesLeft, app.H_LinesRight];
            app.applyLineAppearance(app.H_Lines, colors, lw, 1);
            
            app.UpdateRealTimeSettings();
            if preserveLegend
                app.restoreLegendState(ax, legendState);
            end
        end

        function UIChanged(app, varargin), app.UpdateRealTimeSettings(); end

        function applyAxisFormatting(app, ax_target, axisName, formatType, decPlaces, tickSpace)
            isLog = strcmp(formatType, 'Log坐标');
            if strcmp(axisName, 'X')
                if isLog, ax_target.XScale = 'log'; ax_target.XTickMode = 'auto'; ax_target.XTickLabelMode = 'auto';
                else
                    ax_target.XScale = 'linear';
                    if tickSpace > 0 && ((max(xlim(ax_target)) - min(xlim(ax_target))) / tickSpace < 200)
                        ax_target.XTick = min(xlim(ax_target)) : tickSpace : max(xlim(ax_target));
                    else, ax_target.XTickMode = 'auto'; 
                    end
                    ax_target.XTickLabelMode = 'auto'; 
                    if strcmp(formatType, '常规小数'), ax_target.XAxis.Exponent = 0; xtickformat(ax_target, ['%.', num2str(decPlaces), 'f']);
                    elseif strcmp(formatType, '常规整数'), ax_target.XAxis.Exponent = 0; xtickformat(ax_target, '%.0f');
                    elseif strcmp(formatType, '科学计数')
                        ax_target.XAxis.Exponent = 0; ticks = ax_target.XTick; labels = cell(1, length(ticks));
                        for i = 1:length(ticks)
                            val = ticks(i);
                            if val == 0, labels{i} = '0'; else
                                exp_val = floor(log10(abs(val))); base_val = val / 10^exp_val;
                                base_str = sprintf(['%.', num2str(decPlaces), 'f'], base_val);
                                labels{i} = [base_str, '\times10^{', num2str(exp_val), '}'];
                            end
                        end
                        ax_target.XTickLabel = labels;
                    end
                end
            elseif strcmp(axisName, 'Y')
                if isLog, ax_target.YScale = 'log'; ax_target.YTickMode = 'auto'; ax_target.YTickLabelMode = 'auto';
                else
                    ax_target.YScale = 'linear';
                    if tickSpace > 0 && ((max(ylim(ax_target)) - min(ylim(ax_target))) / tickSpace < 200)
                        ax_target.YTick = min(ylim(ax_target)) : tickSpace : max(ylim(ax_target));
                    else, ax_target.YTickMode = 'auto'; 
                    end
                    ax_target.YTickLabelMode = 'auto';
                    if strcmp(formatType, '常规小数'), app.setYAxisExponentZero(ax_target); ytickformat(ax_target, ['%.', num2str(decPlaces), 'f']);
                    elseif strcmp(formatType, '常规整数'), app.setYAxisExponentZero(ax_target); ytickformat(ax_target, '%.0f');
                    elseif strcmp(formatType, '科学计数')
                        app.setYAxisExponentZero(ax_target); ticks = ax_target.YTick; labels = cell(1, length(ticks));
                        for i = 1:length(ticks)
                            val = ticks(i);
                            if val == 0, labels{i} = '0'; else
                                exp_val = floor(log10(abs(val))); base_val = val / 10^exp_val;
                                base_str = sprintf(['%.', num2str(decPlaces), 'f'], base_val);
                                labels{i} = [base_str, '\times10^{', num2str(exp_val), '}'];
                            end
                        end
                        ax_target.YTickLabel = labels;
                    end
                end
            end
        end

        function UpdateRealTimeSettings(app)
            if ~isvalid(app) || ~isvalid(app.UIAxes), return; end
            w = app.WidthEdit.Value; h = app.HeightEdit.Value;
            ax = app.UIAxes;
            app.HasRightAxis = ~isempty(app.Y_Right_Data_Plot);
            app.updateRightAxisControls();
            
            yyaxis(ax, 'left');
            ax.FontName = app.FontDrop.Value; ax.FontSize = app.FontSizeEdit.Value;
            ax.LineWidth = app.AxisWidthEdit.Value; ax.FontWeight = fastif(app.FontBoldChk.Value, 'bold', 'normal');
            ax.Box = 'off';
            ax.XAxisLocation = 'bottom';
            ax.TickDir = fastif(app.TickOutChk.Value, 'out', 'in'); 
            app.applyAxisTextStyle(ax, 'X', 1);
            app.applyAxisTextStyle(ax, 'YLeft', 1);
            
            grid_state = fastif(app.GridLineChk.Value, 'on', 'off');
            ax.XGrid = grid_state; ax.YGrid = grid_state;
            ax.Color = 'w'; 
            
            ax.XLabel.String = app.XLabelEdit.Value; ax.YLabel.String = app.YLabelEdit.Value;
            ax.TickLabelInterpreter = 'tex'; 
            
            x_min = app.XMinEdit.Value; x_max = app.XMaxEdit.Value;
            if x_max > x_min
                if strcmp(app.XFormatDrop.Value, 'Log坐标'), xlim(ax, [max(1e-12, x_min), max(1e-11, x_max)]);
                else, xlim(ax, [x_min, x_max]); end
            end
            app.applyAxisFormatting(ax, 'X', app.XFormatDrop.Value, round(max(app.XDecEdit.Value, 0)), app.XTickSpaceEdit.Value);
            
            yyaxis(ax, 'left');
            y_min = app.YMinEdit.Value; y_max = app.YMaxEdit.Value;
            if y_max > y_min
                if strcmp(app.YFormatDrop.Value, 'Log坐标'), ylim(ax, [max(1e-12, y_min), max(1e-11, y_max)]);
                else, ylim(ax, [y_min, y_max]); end
            end
            app.applyAxisFormatting(ax, 'Y', app.YFormatDrop.Value, round(max(app.YDecEdit.Value, 0)), app.YTickSpaceEdit.Value);

            yyaxis(ax, 'right');
            ax.FontName = app.FontDrop.Value; ax.FontSize = app.FontSizeEdit.Value;
            ax.LineWidth = app.AxisWidthEdit.Value; ax.FontWeight = fastif(app.FontBoldChk.Value, 'bold', 'normal');
            ax.TickDir = fastif(app.TickOutChk.Value, 'out', 'in');
            ax.YLabel.String = app.YRightLabelEdit.Value;
            if app.HasRightAxis
                app.applyAxisTextStyle(ax, 'YRight', 1);
                yr_min = app.YRightMinEdit.Value; yr_max = app.YRightMaxEdit.Value;
                if yr_max > yr_min
                    if strcmp(app.YRightFormatDrop.Value, 'Log坐标'), ylim(ax, [max(1e-12, yr_min), max(1e-11, yr_max)]);
                    else, ylim(ax, [yr_min, yr_max]); end
                end
                app.applyAxisFormatting(ax, 'Y', app.YRightFormatDrop.Value, round(max(app.YRightDecEdit.Value, 0)), app.YRightTickSpaceEdit.Value);
                try ax.YAxis(2).Visible = 'on'; catch, end
            else
                try ax.YAxis(2).Visible = 'off'; catch, end
            end
            yyaxis(ax, 'left');
            ax.XLabel.String = app.XLabelEdit.Value;
            ax.YLabel.String = app.YLabelEdit.Value;
            ax.XAxisLocation = 'bottom';
            ax.Box = 'off';
            app.applyAxisTextStyle(ax, 'X', 1);
            app.applyAxisTextStyle(ax, 'YLeft', 1);
            
            num_lines = length(app.H_Lines);
            if num_lines > 0
                colors = app.getColorMap(app.ColorDrop.Value, num_lines);
                lw = app.LineWidthEdit.Value;
                app.applyLineAppearance(app.H_Lines, colors, lw, 1);
            end
            
            app.drawFrameBorder(ax, 1);
            
            if app.LgdVisibleChk.Value && num_lines > 0
                if isempty(ax.Legend)
                    padded_labels = cell(1, num_lines);
                    for i = 1:num_lines, padded_labels{i} = [char(app.LegendLabels{i}), '    ']; end
                    lgd = legend(ax, app.H_Lines, padded_labels, 'Location', 'northwest');
                    lgd.ItemTokenSize = [15, 18];
                end
                if ~isempty(ax.Legend)
                    lgd = ax.Legend; 
                    lgd.NumColumns = max(1, round(app.LgdColsEdit.Value));
                    lgd.FontName = app.FontDrop.Value; lgd.FontSize = app.LgdFontEdit.Value;
                    lgd.FontWeight = fastif(app.FontBoldChk.Value, 'bold', 'normal');
                    
                    app.applyLegendBoxStyle(lgd);
                    
                    lgd.Visible = 'on';
                end
            else
                legend(ax, 'off');
            end
            
            drawnow; 
            ti = ax.TightInset; 
            
            margin = 20;
            left = ti(1) + margin; 
            bottom = ti(2) + margin;
            ax_w = max(10, w - ti(1) - ti(3) - margin * 2); 
            ax_h = max(10, h - ti(2) - ti(4) - margin * 2);
            
            ax.Position = [left, bottom, ax_w, ax_h];
            
            if app.LgdVisibleChk.Value && num_lines > 0 && ~isempty(ax.Legend)
                app.UpdateLegendPosOnly(app.LgdXSlider.Value, app.LgdYSlider.Value);
            end
        end

        function updateRightAxisControls(app)
            state = fastif(app.HasRightAxis, 'on', 'off');
            try app.YRightMinEdit.Enable = state; app.YRightMaxEdit.Enable = state; catch, end
            try app.YRightTickSpaceEdit.Enable = state; app.YRightFormatDrop.Enable = state; app.YRightDecEdit.Enable = state; catch, end
            try app.YRightLabelEdit.Enable = state; catch, end
        end

        function setProgress(app, pct, textValue)
            try
                pct = max(0, min(100, pct));
                bgPos = app.ProgressBg.Position;
                app.ProgressFill.Position = [0, 0, max(0, bgPos(3) * pct / 100), max(1, bgPos(4))];
                if app.ProgressText.Parent == app.ProgressBg
                    app.ProgressText.Position = [0, 0, max(1, bgPos(3)), max(1, bgPos(4))];
                end
                app.ProgressText.Text = textValue;
                drawnow limitrate;
            catch
            end
        end

        function PreviewBtnPushed(app, varargin), app.IsPlaying = false; app.PlotStaticFull(true); app.setProgress(100, '静态预览已生成'); end
        function DrawBtnPushed(app, varargin), if app.IsPlaying, return; end; if isempty(app.H_Lines), app.PlotStaticFull(); end; if isempty(app.H_Lines), return; end; app.IsPlaying = true; app.CurrentFrame = 1; app.RunAnimationLoop(); end
        function ResetBtnPushed(app, varargin), app.IsPlaying = false; app.CurrentFrame = 1; for i = 1:length(app.H_Lines), if isgraphics(app.H_Lines(i)), set(app.H_Lines(i), 'XData', nan, 'YData', nan, 'MarkerIndices', []); end; end; drawnow; app.setProgress(0, '等待导出...'); end

        function RunAnimationLoop(app)
            interval = max(1, round(app.IntervalEdit.Value)); num_points = size(app.Y_Data_Plot, 1); num_lines = length(app.H_Lines);
            while app.CurrentFrame <= num_points && app.IsPlaying
                if ~isvalid(app.UIFigure), return; end
                k = app.CurrentFrame;
                for i = 1:num_lines, set(app.H_Lines(i), 'XData', app.X_Data_Plot(1:k), 'YData', app.Y_Data_Plot(1:k, i)); end
                app.applySparseMarkerIndices(app.H_Lines);
                drawnow;
                if app.CurrentFrame == num_points, app.CurrentFrame = app.CurrentFrame + 1; break; end
                next_frame = app.CurrentFrame + interval;
                if next_frame > num_points, app.CurrentFrame = num_points; else, app.CurrentFrame = next_frame; end
            end
            if app.CurrentFrame > num_points, app.IsPlaying = false; end
        end

        function [fig, ax, lines] = CreateHiddenRenderAxes(app, w, h)
            % --- 核心架构重构：手动计算物理缩放，避开 MATLAB 的 print 高 DPI 渲染 Bug ---
            % 获取真实的屏幕 DPI 作为基准
            screen_dpi = get(groot, 'ScreenPixelsPerInch');
            if isempty(screen_dpi) || screen_dpi <= 0, screen_dpi = 96; end
            
            % 用户期望的高清 DPI
            dpi_val = round(max(72, app.DPIEdit.Value));
            % 计算物理缩放倍率
            scale = dpi_val / screen_dpi;

            % 按照缩放倍率直接生成巨大的高分辨率隐形画布
            w_scaled = round(w * scale);
            h_scaled = round(h * scale);

            fig = figure('Visible', 'off', 'Position', [100 100 w_scaled h_scaled], 'Color', 'w', 'ToolBar', 'none', 'MenuBar', 'none');
            ax = axes(fig, 'Units', 'pixels');
            yyaxis(ax, 'left'); hold(ax, 'on');
            
            num_left = size(app.Y_Left_Data_Plot, 2);
            num_right = size(app.Y_Right_Data_Plot, 2);
            num_lines = num_left + num_right;
            colors = app.getColorMap(app.ColorDrop.Value, num_lines);
            
            lines = gobjects(1, num_lines); 
            lw = app.LineWidthEdit.Value * scale; % 缩放：线条宽度
            yyaxis(ax, 'left');
            for i = 1:num_left
                lines(i) = plot(ax, app.X_Data_Plot, app.Y_Left_Data_Plot(:, i), 'LineWidth', lw, 'Color', colors(i,:)); 
            end
            yyaxis(ax, 'right'); hold(ax, 'on');
            for i = 1:num_right
                lines(num_left + i) = plot(ax, app.X_Data_Plot, app.Y_Right_Data_Plot(:, i), 'LineWidth', lw, 'Color', colors(num_left + i,:)); 
            end
            app.applyLineAppearance(lines, colors, lw, scale);
            
            yyaxis(ax, 'left');
            ax.FontName = app.FontDrop.Value; 
            ax.FontSize = app.FontSizeEdit.Value * scale; % 缩放：坐标轴字号
            ax.LineWidth = app.AxisWidthEdit.Value * scale; % 缩放：坐标轴外框粗细
            ax.FontWeight = fastif(app.FontBoldChk.Value, 'bold', 'normal');
            ax.Box = 'off'; 
            ax.XAxisLocation = 'bottom';
            ax.TickDir = fastif(app.TickOutChk.Value, 'out', 'in'); 
            app.applyAxisTextStyle(ax, 'X', scale);
            app.applyAxisTextStyle(ax, 'YLeft', scale);
            
            grid_state = fastif(app.GridLineChk.Value, 'on', 'off');
            ax.XGrid = grid_state; ax.YGrid = grid_state;
            ax.Color = 'w';
            ax.XLabel.String = app.XLabelEdit.Value; ax.YLabel.String = app.YLabelEdit.Value;
            ax.TickLabelInterpreter = 'tex';
            
            if app.XMaxEdit.Value > app.XMinEdit.Value
                if strcmp(app.XFormatDrop.Value, 'Log坐标'), xlim(ax, [max(1e-12, app.XMinEdit.Value), max(1e-11, app.XMaxEdit.Value)]);
                else, xlim(ax, [app.XMinEdit.Value, app.XMaxEdit.Value]); end
            end
            app.applyAxisFormatting(ax, 'X', app.XFormatDrop.Value, round(max(0, app.XDecEdit.Value)), app.XTickSpaceEdit.Value);
            
            yyaxis(ax, 'left');
            if app.YMaxEdit.Value > app.YMinEdit.Value
                if strcmp(app.YFormatDrop.Value, 'Log坐标'), ylim(ax, [max(1e-12, app.YMinEdit.Value), max(1e-11, app.YMaxEdit.Value)]);
                else, ylim(ax, [app.YMinEdit.Value, app.YMaxEdit.Value]); end
            end
            app.applyAxisFormatting(ax, 'Y', app.YFormatDrop.Value, round(max(0, app.YDecEdit.Value)), app.YTickSpaceEdit.Value);

            yyaxis(ax, 'right');
            ax.FontName = app.FontDrop.Value;
            ax.FontSize = app.FontSizeEdit.Value * scale;
            ax.LineWidth = app.AxisWidthEdit.Value * scale;
            ax.FontWeight = fastif(app.FontBoldChk.Value, 'bold', 'normal');
            ax.TickDir = fastif(app.TickOutChk.Value, 'out', 'in');
            ax.YLabel.String = app.YRightLabelEdit.Value;
            if app.HasRightAxis
                app.applyAxisTextStyle(ax, 'YRight', scale);
                if app.YRightMaxEdit.Value > app.YRightMinEdit.Value
                    if strcmp(app.YRightFormatDrop.Value, 'Log坐标'), ylim(ax, [max(1e-12, app.YRightMinEdit.Value), max(1e-11, app.YRightMaxEdit.Value)]);
                    else, ylim(ax, [app.YRightMinEdit.Value, app.YRightMaxEdit.Value]); end
                end
                app.applyAxisFormatting(ax, 'Y', app.YRightFormatDrop.Value, round(max(0, app.YRightDecEdit.Value)), app.YRightTickSpaceEdit.Value);
                try ax.YAxis(2).Visible = 'on'; catch, end
            else
                try ax.YAxis(2).Visible = 'off'; catch, end
            end
            yyaxis(ax, 'left');
            ax.XLabel.String = app.XLabelEdit.Value;
            ax.YLabel.String = app.YLabelEdit.Value;
            ax.XAxisLocation = 'bottom';
            ax.Box = 'off';
            app.applyAxisTextStyle(ax, 'X', scale);
            app.applyAxisTextStyle(ax, 'YLeft', scale);
            
            app.drawFrameBorder(ax, scale);
            
            % --- 渲染图例，同步进行物理缩放 ---
            if app.LgdVisibleChk.Value && num_lines > 0
                padded_labels = cell(1, num_lines); 
                for i = 1:num_lines, padded_labels{i} = [char(app.LegendLabels{i}), '    ']; end
                lgd = legend(ax, lines, padded_labels, 'Location', 'northwest', 'NumColumns', max(1, round(app.LgdColsEdit.Value)));
                lgd.FontName = app.FontDrop.Value; 
                lgd.FontSize = app.LgdFontEdit.Value * scale; % 缩放：图例字号
                lgd.FontWeight = fastif(app.FontBoldChk.Value, 'bold', 'normal');
                
                app.applyLegendBoxStyle(lgd);
                
                % 缩放：图例内部的线条标记长度 (这就是之前比例失调的元凶之一)
                lgd.ItemTokenSize = [15 * scale, 18 * scale]; 
            else
                legend(ax, 'off');
            end
            
            drawnow; 
            ti = ax.TightInset; 
            
            margin = 20 * scale; % 缩放：排版边距
            left = ti(1) + margin; 
            bottom = ti(2) + margin;
            ax_w = max(10, w_scaled - ti(1) - ti(3) - margin * 2); 
            ax_h = max(10, h_scaled - ti(2) - ti(4) - margin * 2);
            ax.Position = [left, bottom, ax_w, ax_h];
            
            drawnow; 
            
            yyaxis(ax, 'left');
            ax.XLimMode = 'manual';
            ax.YLimMode = 'manual';
            ax.XTickMode = 'manual';
            ax.YTickMode = 'manual';
            ax.XTickLabelMode = 'manual';
            ax.YTickLabelMode = 'manual';
            if app.HasRightAxis
                yyaxis(ax, 'right');
                ax.YLimMode = 'manual';
                ax.YTickMode = 'manual';
                ax.YTickLabelMode = 'manual';
                yyaxis(ax, 'left');
            end
            
            if app.LgdVisibleChk.Value && num_lines > 0
                % 使用像素绝对坐标进行无损锁定
                ax.Units = 'pixels';
                ax_pos = ax.Position;
                
                lgd.Units = 'pixels';
                lgd_pos = lgd.Position;
                
                nx = ax_pos(1) + app.LgdXSlider.Value * max(0.001, ax_pos(3) - lgd_pos(3));
                ny = ax_pos(2) + app.LgdYSlider.Value * max(0.001, ax_pos(4) - lgd_pos(4));
                
                lgd.Location = 'none'; 
                lgd.Position(1:2) = [nx, ny];
                % 这里不要加 AutoUpdate = 'off'，让其自然定型
            end
        end

        function ExportBtnPushed(app, varargin)
            if isempty(app.H_Lines), uialert(app.UIFigure, '请先在左侧勾选需要导出的曲线！', '提示'); app.restoreMainWindow(); return; end
            w = app.WidthEdit.Value; h = app.HeightEdit.Value;
            dpi_val = round(max(72, app.DPIEdit.Value)); 
            delay = 0.1; interval = max(1, round(app.IntervalEdit.Value));
            formatValue = app.ExportFormatDrop.Value;
            isGIF = strcmp(formatValue, 'GIF'); isMP4 = strcmp(formatValue, 'MP4');
            isPNGRadio = strcmp(formatValue, 'PNGS');
            isStaticPNG = strcmp(formatValue, 'PNG'); isStaticJPG = strcmp(formatValue, 'JPG'); isStaticTIF = strcmp(formatValue, 'TIF');
            isStatic = isStaticPNG || isStaticJPG || isStaticTIF;
            
            if isGIF, [file, path] = uiputfile('*.gif', '保存 GIF 动画');
            elseif isMP4, [file, path] = uiputfile('*.mp4', '保存 MP4 动画');
            elseif isStaticPNG, [file, path] = uiputfile('*.png', '保存单张 PNG');
            elseif isStaticJPG, [file, path] = uiputfile('*.jpg', '保存单张 JPG');
            elseif isStaticTIF, [file, path] = uiputfile('*.tif', '保存单张 TIF');
            else
                folder = uigetdir('', '选择 PNG 序列保存文件夹');
                file = ''; path = folder;
            end
            app.restoreMainWindow();
            
            if isequal(file, 0) || isequal(path, 0), return; end
            if isPNGRadio, f_path = path; else, f_path = fullfile(path, file); end
            
            [hiddenFig, ~, lines_hidden] = app.CreateHiddenRenderAxes(w, h);
            num_points = size(app.Y_Data_Plot, 1); num_lines = length(lines_hidden);
            
            app.ExportBtn.Text = '导出中...'; app.ExportBtn.Enable = 'off'; 
            app.setProgress(0, '0%'); drawnow;
            
            % --- 无损原生截取设定 ---
            % 既然前面的画布已经按物理尺寸放大了，这里就必须使用屏幕原生 DPI 进行 1:1 截屏输出
            % 这样彻底阻断 MATLAB 擅自在 print 时进行二次缩放打乱图例排版！
            screen_dpi = get(groot, 'ScreenPixelsPerInch');
            if isempty(screen_dpi) || screen_dpi <= 0, screen_dpi = 96; end
            print_res_str = sprintf('-r%d', screen_dpi);
            
            hiddenFig.PaperPositionMode = 'auto';
            hiddenFig.InvertHardcopy = 'off';
            
            try
                % 预热渲染引擎
                try print(hiddenFig, '-RGBImage', print_res_str); catch, end
                
                if isStatic
                    for i = 1:num_lines, set(lines_hidden(i), 'XData', app.X_Data_Plot, 'YData', app.Y_Data_Plot(:, i)); end
                    app.applySparseMarkerIndices(lines_hidden);
                    drawnow; app.setProgress(100, '导出进度: 100%'); drawnow;
                    
                    if isStaticPNG
                        print(hiddenFig, f_path, '-dpng', print_res_str);
                    elseif isStaticJPG
                        print(hiddenFig, f_path, '-djpeg', print_res_str);
                    elseif isStaticTIF
                        print(hiddenFig, f_path, '-dtiff', print_res_str);
                    end
                    
                    close(hiddenFig); app.ExportBtn.Text = '导出选定格式'; app.ExportBtn.Enable = 'on'; app.ProgressText.Text = '导出完成!'; uialert(app.UIFigure, sprintf('高清静态图片(DPI: %d)导出成功！', dpi_val), '完成'); app.restoreMainWindow(); return;
                end
                
                if isMP4, v = VideoWriter(f_path, 'MPEG-4'); v.FrameRate = max(1, round(1 / delay)); v.Quality = 100; open(v); end
                frame_list = 1:interval:num_points; if frame_list(end) ~= num_points, frame_list(end+1) = num_points; end
                total_frames = length(frame_list); frame_idx = 1;
                
                for k = frame_list
                    for i = 1:num_lines, set(lines_hidden(i), 'XData', app.X_Data_Plot(1:k), 'YData', app.Y_Data_Plot(1:k, i)); end
                    app.applySparseMarkerIndices(lines_hidden);
                    drawnow;
                    
                    % 动画渲染：无损物理截取，不再触发引擎二次缩放
                    im = print(hiddenFig, '-RGBImage', print_res_str);
                    
                    if isPNGRadio
                        png_name = fullfile(path, sprintf('frame_%04d.png', frame_idx));
                        imwrite(im, png_name, 'png');
                    else
                        if isGIF
                            [imind, cm] = rgb2ind(im, 256);
                            if frame_idx == 1, imwrite(imind, cm, f_path, 'gif', 'Loopcount', inf, 'DelayTime', delay);
                            else, imwrite(imind, cm, f_path, 'gif', 'WriteMode', 'append', 'DelayTime', delay); end
                        elseif isMP4
                            writeVideo(v, im);
                        end
                    end
                    
                    pct = (frame_idx / total_frames) * 100; app.setProgress(pct, sprintf('导出进度: %.1f%%', pct)); drawnow;
                    frame_idx = frame_idx + 1;
                end
                
                if isMP4, close(v); end
                close(hiddenFig); 
                app.ExportBtn.Text = '导出选定格式'; app.ExportBtn.Enable = 'on'; app.ProgressText.Text = '导出完成!'; 
                uialert(app.UIFigure, '动画导出成功！', '完成');
                app.restoreMainWindow();
                
            catch ME
                if exist('v', 'var') && isMP4, close(v); end
                if exist('hiddenFig', 'var') && isvalid(hiddenFig), close(hiddenFig); end
                app.ExportBtn.Text = '导出选定格式'; app.ExportBtn.Enable = 'on'; app.ProgressText.Text = '导出中止';
                try app.writeErrorLog(ME, '导出图像'); catch, end
                uialert(app.UIFigure, ['导出过程中出现错误: ' ME.message], '导出失败');
                app.restoreMainWindow();
            end
        end
    end

    methods (Access = private)
        function createComponents(app)
            app.UIFigure = uifigure('Name', 'LineAnimationApp (WYSIWYG Edition)', 'Position', [50, 50, 1350, 780]);
            app.UIFigure.CloseRequestFcn = @(src, event) app.safeRun(@() app.AppCloseRequest(src, event), '关闭程序');
            
            app.GridLayout = uigridlayout(app.UIFigure, [2 3]);
            app.GridLayout.RowHeight = {'1x', 24};
            app.GridLayout.ColumnWidth = {300, 450, '1x'}; 
            app.GridLayout.Padding = [4 4 4 4];
            
            %% --- 左侧面板 ---
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;
            leftGrid = uigridlayout(app.LeftPanel, [4 1]);
            leftGrid.RowHeight = {30, 30, 20, '1x'};
            leftGrid.Padding = [5, 5, 5, 5];
            
            app.FindReplacePanel = uipanel(leftGrid, 'BorderType', 'none');
            frLayout = uigridlayout(app.FindReplacePanel, [1 5]);
            frLayout.RowHeight = {'1x'}; 
            frLayout.ColumnWidth = {30, '2x', 30, '2x', 55}; 
            frLayout.Padding = [0 0 0 0];
            
            uilabel(frLayout, 'Text', '查找'); app.FindEdit = uieditfield(frLayout, 'text');
            uilabel(frLayout, 'Text', '替换'); app.ReplaceEdit = uieditfield(frLayout, 'text');
            app.ReplaceBtn = uibutton(frLayout, 'push', 'Text', '执行'); app.ReplaceBtn.ButtonPushedFcn = @(src, event) app.safeRun(@() app.ReplaceBtnPushed(src, event), '替换曲线名称');
            
            btnGrid = uigridlayout(leftGrid, [1 2]); 
            btnGrid.Padding = [0 0 0 0];
            app.SelectAllYBtn = uibutton(btnGrid, 'push', 'Text', '全选左Y'); app.SelectAllYBtn.ButtonPushedFcn = @(src, event) app.safeRun(@() app.SelectAllYPushed(src, event), '全选左Y');
            app.ClearYBtn = uibutton(btnGrid, 'push', 'Text', '全部清空'); app.ClearYBtn.ButtonPushedFcn = @(src, event) app.safeRun(@() app.ClearYPushed(src, event), '清空Y选择');
            
            uilabel(leftGrid, 'Text', '数据列表', 'FontWeight', 'bold', 'FontColor', [0.3 0.3 0.3]);
            app.DataTable = uitable(leftGrid);
            app.DataTable.ColumnName = {'Name', 'X', 'Y左', 'Y右'};
            app.DataTable.ColumnFormat = {'char', 'logical', 'logical', 'logical'};
            app.DataTable.ColumnEditable = [true, true, true, true];
            app.DataTable.ColumnWidth = {150, 40, 45, 45}; 
            app.DataTable.CellEditCallback = @(src, event) app.safeRun(@() app.DataTableEdited(src, event), '更新数据表');
            
            %% --- 中间面板 ---
            app.MiddlePanel = uipanel(app.GridLayout);
            app.MiddlePanel.Layout.Row = 1;
            app.MiddlePanel.Layout.Column = 2;
            midLayout = uigridlayout(app.MiddlePanel, [1 1]);
            midLayout.Padding = [5, 5, 5, 5];
            app.MiddleTabs = uitabgroup(midLayout);
            app.DataTab = uitab(app.MiddleTabs, 'Title', '数据与导出');
            app.AxisTab = uitab(app.MiddleTabs, 'Title', '坐标轴与样式');

            dataExportGrid = uigridlayout(app.DataTab, [4 1]);
            dataExportGrid.RowHeight = {40, 138, 150, '1x'};
            dataExportGrid.RowSpacing = 8;
            dataExportGrid.Padding = [8 8 8 8];
            dataGrid = uigridlayout(dataExportGrid, [1 1]);
            dataGrid.RowHeight = {34};
            dataGrid.Padding = [0 0 0 0];
            app.LoadBtn = uibutton(dataGrid, 'push', 'Text', '选择数据文件');
            app.LoadBtn.BackgroundColor = [0 0.4470 0.7410]; app.LoadBtn.FontColor = 'white'; app.LoadBtn.FontWeight = 'bold';
            app.LoadBtn.ButtonPushedFcn = @(src, event) app.safeRun(@() app.LoadBtnPushed(src, event), '加载数据');

            axisStyleMain = uigridlayout(app.AxisTab, [3 1]);
            axisStyleMain.RowHeight = {126, 124, 148};
            axisStyleMain.RowSpacing = 24;
            axisStyleMain.Padding = [10 8 10 8];
            app.AxesPanel = uipanel(axisStyleMain, 'BorderType', 'none');
            axisGrid = uigridlayout(app.AxesPanel, [4 6]);
            axisGrid.RowHeight = {22, 30, 30, 30};
            axisGrid.ColumnWidth = {32, '1x', '1x', 58, 92, 42};
            axisGrid.ColumnSpacing = 4;
            axisGrid.RowSpacing = 4;
            axisGrid.Padding = [0 0 0 0];

            uilabel(axisGrid, 'Text', '轴');
            uilabel(axisGrid, 'Text', '最小值');
            uilabel(axisGrid, 'Text', '最大值');
            uilabel(axisGrid, 'Text', '间距');
            uilabel(axisGrid, 'Text', '格式');
            uilabel(axisGrid, 'Text', '小数');
            uilabel(axisGrid, 'Text', 'X');
            app.XMinEdit = uieditfield(axisGrid, 'numeric', 'ValueDisplayFormat', '%.15g'); app.XMinEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新X范围');
            app.XMaxEdit = uieditfield(axisGrid, 'numeric', 'ValueDisplayFormat', '%.15g'); app.XMaxEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新X范围');
            app.XTickSpaceEdit = uieditfield(axisGrid, 'numeric', 'Value', 0); app.XTickSpaceEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新X刻度');
            app.XFormatDrop = uidropdown(axisGrid, 'Items', {'常规整数', '常规小数', '科学计数', 'Log坐标'}, 'Value', '常规整数'); app.XFormatDrop.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新X格式');
            app.XDecEdit = uieditfield(axisGrid, 'numeric', 'Value', 0); app.XDecEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新X小数');
            uilabel(axisGrid, 'Text', '左Y');
            app.YMinEdit = uieditfield(axisGrid, 'numeric', 'ValueDisplayFormat', '%.15g'); app.YMinEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新左Y范围');
            app.YMaxEdit = uieditfield(axisGrid, 'numeric', 'ValueDisplayFormat', '%.15g'); app.YMaxEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新左Y范围');
            app.YTickSpaceEdit = uieditfield(axisGrid, 'numeric', 'Value', 0); app.YTickSpaceEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新左Y刻度');
            app.YFormatDrop = uidropdown(axisGrid, 'Items', {'常规整数', '常规小数', '科学计数', 'Log坐标'}, 'Value', '常规整数'); app.YFormatDrop.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新左Y格式');
            app.YDecEdit = uieditfield(axisGrid, 'numeric', 'Value', 0); app.YDecEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新左Y小数');
            uilabel(axisGrid, 'Text', '右Y');
            app.YRightMinEdit = uieditfield(axisGrid, 'numeric', 'ValueDisplayFormat', '%.15g'); app.YRightMinEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新右Y范围');
            app.YRightMaxEdit = uieditfield(axisGrid, 'numeric', 'ValueDisplayFormat', '%.15g'); app.YRightMaxEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新右Y范围');
            app.YRightTickSpaceEdit = uieditfield(axisGrid, 'numeric', 'Value', 0); app.YRightTickSpaceEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新右Y刻度');
            app.YRightFormatDrop = uidropdown(axisGrid, 'Items', {'常规整数', '常规小数', '科学计数', 'Log坐标'}, 'Value', '常规整数'); app.YRightFormatDrop.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新右Y格式');
            app.YRightDecEdit = uieditfield(axisGrid, 'numeric', 'Value', 0); app.YRightDecEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新右Y小数');

            app.CurvePanel = uipanel(axisStyleMain, 'BorderType', 'none');
            globalGrid = uigridlayout(app.CurvePanel, [4 4]);
            globalGrid.RowHeight = {28, 28, 28, 28};
            globalGrid.ColumnWidth = {56, '1x', 70, '1x'};
            globalGrid.ColumnSpacing = 4;
            globalGrid.RowSpacing = 4;
            globalGrid.Padding = [0 0 0 0];
            uilabel(globalGrid, 'Text', '配色');
            app.ColorDrop = uidropdown(globalGrid, 'Items', app.getColorMapNames(), 'Value', 'Nature/NPG'); app.ColorDrop.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新配色');
            uilabel(globalGrid, 'Text', '字体', 'HorizontalAlignment', 'right');
            fonts = app.getAvailableFonts();
            defaultFont = 'Times New Roman';
            if ~any(strcmp(fonts, defaultFont)), defaultFont = fonts{1}; end
            app.FontDrop = uidropdown(globalGrid, 'Items', fonts, 'Value', defaultFont); app.FontDrop.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新字体');
            uilabel(globalGrid, 'Text', '轴宽');
            app.AxisWidthEdit = uieditfield(globalGrid, 'numeric', 'Value', 1.5); app.AxisWidthEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新轴宽');
            uilabel(globalGrid, 'Text', '坐标字号', 'HorizontalAlignment', 'right');
            app.FontSizeEdit = uieditfield(globalGrid, 'numeric', 'Value', 15); app.FontSizeEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新坐标字号');
            uilabel(globalGrid, 'Text', '线宽');
            app.LineWidthEdit = uieditfield(globalGrid, 'numeric', 'Value', 2); app.LineWidthEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新线宽');
            uilabel(globalGrid, 'Text', '图例字号', 'HorizontalAlignment', 'right');
            app.LgdFontEdit = uieditfield(globalGrid, 'numeric', 'Value', 12); app.LgdFontEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新图例字号');
            uilabel(globalGrid, 'Text', '图例形状');
            app.LegendShapeDrop = uidropdown(globalGrid, 'Items', app.getLegendShapeItems(), 'Value', '仅线'); app.LegendShapeDrop.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新图例形状');
            uilabel(globalGrid, 'Text', '标记大小', 'HorizontalAlignment', 'right');
            app.MarkerSizeEdit = uieditfield(globalGrid, 'numeric', 'Value', 6, 'Limits', [1 30]); app.MarkerSizeEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新标记大小');

            axisStylePanel = uipanel(axisStyleMain, 'BorderType', 'none');
            axisStyleGrid = uigridlayout(axisStylePanel, [4 6]);
            axisStyleGrid.RowHeight = {22, 32, 32, 32};
            axisStyleGrid.ColumnWidth = {28, 34, 62, 62, '1x', 42};
            axisStyleGrid.ColumnSpacing = 4;
            axisStyleGrid.RowSpacing = 6;
            axisStyleGrid.Padding = [0 0 0 0];
            uilabel(axisStyleGrid, 'Text', '轴');
            uilabel(axisStyleGrid, 'Text', '覆盖');
            uilabel(axisStyleGrid, 'Text', '轴色');
            uilabel(axisStyleGrid, 'Text', '标题色');
            uilabel(axisStyleGrid, 'Text', '字体');
            uilabel(axisStyleGrid, 'Text', '字号');
            uilabel(axisStyleGrid, 'Text', 'X');
            app.XStyleOverrideChk = uicheckbox(axisStyleGrid, 'Text', '', 'Value', false); app.XStyleOverrideChk.ValueChangedFcn = @(src, event) app.safeRun(@() app.syncAxisStyleEnable(src, event), '切换X轴样式覆盖');
            app.XAxisColorBtn = uibutton(axisStyleGrid, 'push'); app.XAxisColorBtn.ButtonPushedFcn = @(src, event) app.chooseColor(app.XAxisColorBtn, '选择X轴颜色');
            app.XTitleColorBtn = uibutton(axisStyleGrid, 'push'); app.XTitleColorBtn.ButtonPushedFcn = @(src, event) app.chooseColor(app.XTitleColorBtn, '选择X标题颜色');
            app.XAxisFontDrop = uidropdown(axisStyleGrid, 'Items', fonts, 'Value', defaultFont); app.XAxisFontDrop.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新X轴字体');
            app.XAxisFontSizeEdit = uieditfield(axisStyleGrid, 'numeric', 'Value', 15); app.XAxisFontSizeEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新X轴字号');
            uilabel(axisStyleGrid, 'Text', '左Y');
            app.YLeftStyleOverrideChk = uicheckbox(axisStyleGrid, 'Text', '', 'Value', false); app.YLeftStyleOverrideChk.ValueChangedFcn = @(src, event) app.safeRun(@() app.syncAxisStyleEnable(src, event), '切换左Y样式覆盖');
            app.YLeftAxisColorBtn = uibutton(axisStyleGrid, 'push'); app.YLeftAxisColorBtn.ButtonPushedFcn = @(src, event) app.chooseColor(app.YLeftAxisColorBtn, '选择左Y轴颜色');
            app.YLeftTitleColorBtn = uibutton(axisStyleGrid, 'push'); app.YLeftTitleColorBtn.ButtonPushedFcn = @(src, event) app.chooseColor(app.YLeftTitleColorBtn, '选择左Y标题颜色');
            app.YLeftAxisFontDrop = uidropdown(axisStyleGrid, 'Items', fonts, 'Value', defaultFont); app.YLeftAxisFontDrop.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新左Y轴字体');
            app.YLeftAxisFontSizeEdit = uieditfield(axisStyleGrid, 'numeric', 'Value', 15); app.YLeftAxisFontSizeEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新左Y轴字号');
            uilabel(axisStyleGrid, 'Text', '右Y');
            app.YRightStyleOverrideChk = uicheckbox(axisStyleGrid, 'Text', '', 'Value', false); app.YRightStyleOverrideChk.ValueChangedFcn = @(src, event) app.safeRun(@() app.syncAxisStyleEnable(src, event), '切换右Y样式覆盖');
            app.YRightAxisColorBtn = uibutton(axisStyleGrid, 'push'); app.YRightAxisColorBtn.ButtonPushedFcn = @(src, event) app.chooseColor(app.YRightAxisColorBtn, '选择右Y轴颜色');
            app.YRightTitleColorBtn = uibutton(axisStyleGrid, 'push'); app.YRightTitleColorBtn.ButtonPushedFcn = @(src, event) app.chooseColor(app.YRightTitleColorBtn, '选择右Y标题颜色');
            app.YRightAxisFontDrop = uidropdown(axisStyleGrid, 'Items', fonts, 'Value', defaultFont); app.YRightAxisFontDrop.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新右Y轴字体');
            app.YRightAxisFontSizeEdit = uieditfield(axisStyleGrid, 'numeric', 'Value', 15); app.YRightAxisFontSizeEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新右Y轴字号');
            app.setColorButton(app.XAxisColorBtn, [0 0 0]); app.setColorButton(app.XTitleColorBtn, [0 0 0]);
            app.setColorButton(app.YLeftAxisColorBtn, [0 0 0]); app.setColorButton(app.YLeftTitleColorBtn, [0 0 0]);
            app.setColorButton(app.YRightAxisColorBtn, [0.15 0.15 0.15]); app.setColorButton(app.YRightTitleColorBtn, [0.15 0.15 0.15]);

            app.ExportPanel = uipanel(dataExportGrid, 'BorderType', 'none'); 
            exportGrid = uigridlayout(app.ExportPanel, [4 2]);
            exportGrid.RowHeight = {30, 30, 30, 30};
            exportGrid.ColumnWidth = {72, '1x'};
            exportGrid.ColumnSpacing = 4;
            exportGrid.RowSpacing = 6;
            exportGrid.Padding = [0 0 0 0];
            uilabel(exportGrid, 'Text', '导出宽高');
            sizeGrid = uigridlayout(exportGrid, [1 2]); sizeGrid.Padding = [0 0 0 0];
            app.WidthEdit = uieditfield(sizeGrid, 'numeric', 'Value', 800); app.WidthEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UpdateAxesSize(src, event), '更新画布宽度');
            app.HeightEdit = uieditfield(sizeGrid, 'numeric', 'Value', 500); app.HeightEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UpdateAxesSize(src, event), '更新画布高度');
            uilabel(exportGrid, 'Text', '动画间隔');
            app.IntervalEdit = uieditfield(exportGrid, 'numeric', 'Value', 10);
            uilabel(exportGrid, 'Text', '导出DPI');
            app.DPIEdit = uieditfield(exportGrid, 'numeric', 'Value', 300);
            uilabel(exportGrid, 'Text', '导出格式');
            app.ExportFormatDrop = uidropdown(exportGrid, ...
                'Items', {'GIF 动图', 'MP4 视频', 'PNG 序列', 'PNG 单图', 'JPG 单图', 'TIF 单图'}, ...
                'ItemsData', {'GIF', 'MP4', 'PNGS', 'PNG', 'JPG', 'TIF'}, ...
                'Value', 'PNG');

            actionGrid = uigridlayout(dataExportGrid, [4 1]);
            actionGrid.RowHeight = {34, 34, 34, 24};
            actionGrid.RowSpacing = 8;
            actionGrid.Padding = [0 0 0 0];
            dataBtnGrid = uigridlayout(actionGrid, [1 2]); dataBtnGrid.Padding = [0 0 0 0];
            app.PreviewBtn = uibutton(dataBtnGrid, 'push', 'Text', '静态预览'); app.PreviewBtn.ButtonPushedFcn = @(src, event) app.safeRun(@() app.PreviewBtnPushed(src, event), '静态预览');
            app.DrawBtn = uibutton(dataBtnGrid, 'push', 'Text', '绘制动图'); app.DrawBtn.ButtonPushedFcn = @(src, event) app.safeRun(@() app.DrawBtnPushed(src, event), '绘制动图');
            app.ResetBtn = uibutton(actionGrid, 'push', 'Text', '初始化动画'); app.ResetBtn.ButtonPushedFcn = @(src, event) app.safeRun(@() app.ResetBtnPushed(src, event), '初始化动画');
            app.ExportBtn = uibutton(actionGrid, 'push', 'Text', '导出选定格式', 'BackgroundColor', [0.4660 0.6740 0.1880], 'FontColor', 'white', 'FontWeight', 'bold');
            app.ExportBtn.ButtonPushedFcn = @(src, event) app.safeRun(@() app.ExportBtnPushed(src, event), '导出图像');
            app.ProgressBg = uipanel(actionGrid, 'BackgroundColor', [0.85 0.85 0.85], 'BorderType', 'line');
            app.ProgressFill = uipanel(app.ProgressBg, 'Position', [0, 0, 0, 22], 'BackgroundColor', [0.4660 0.6740 0.1880], 'BorderType', 'none');
            app.ProgressText = uilabel(app.ProgressBg, 'Text', '等待导出...', 'Position', [0, 0, 260, 22], 'HorizontalAlignment', 'center', 'FontColor', 'k', 'FontSize', 10);
            uilabel(dataExportGrid, ...
                'Text', sprintf(['操作事项\n', ...
                '1. 先选择数据文件，再在左侧表格中勾选一个 X 列。\n', ...
                '2. Y左 和 Y右 可分别勾选；未使用右轴时右轴输入会自动禁用。\n', ...
                '3. 静态预览用于快速检查坐标范围、图例、字体和配色。\n', ...
                '4. 初始化动画会清空当前曲线显示，但不会清空已加载数据。\n', ...
                '5. 导出前建议确认宽高、DPI、动画间隔和导出格式。\n', ...
                '6. GIF/MP4/PNG序列会按动画间隔抽帧；PNG/JPG/TIF 单图导出完整曲线。\n', ...
                '7. 若修改字体、颜色、图例形状或双 y 轴设置，建议先静态预览再导出。']), ...
                'WordWrap', 'on', ...
                'FontColor', [0.45 0.45 0.45], ...
                'FontSize', 10, ...
                'VerticalAlignment', 'top');
            
            %% --- 右侧面板 ---
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 3;
            rightLayout = uigridlayout(app.RightPanel, [2 1]);
            rightLayout.RowHeight = {'1x', 140}; 
            rightLayout.Padding = [0 0 0 0];
            
            app.AxesWrapper = uipanel(rightLayout, 'Scrollable', 'on', 'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94], 'AutoResizeChildren', 'off');
            app.AxesWrapper.SizeChangedFcn = @(src, event) app.safeRun(@() app.UpdateAxesSize(src, event), '调整画布尺寸');
            
            app.PlotArea = uipanel(app.AxesWrapper, 'Units', 'pixels', 'BorderType', 'line', 'BackgroundColor', 'w', 'HighlightColor', [0.7 0.7 0.7]);
            
            app.UIAxes = axes(app.PlotArea, 'Units', 'pixels');
            app.UIAxes.Toolbar.Visible = 'off';
            disableDefaultInteractivity(app.UIAxes); 
            
            % --- 底部控制面板 ---
            bottomPanel = uipanel(rightLayout, 'BorderType', 'none');
            app.BottomLayout = uigridlayout(bottomPanel, [3, 1]);
            app.BottomLayout.RowHeight = {30, 30, 40};
            app.BottomLayout.Padding = [0 0 0 0];
            
            % 第一排：标题栏
            r1 = uigridlayout(app.BottomLayout, [1, 6]); r1.Layout.Row = 1;
            r1.ColumnWidth = {54, '1x', 58, '1x', 58, '1x'};
            r1.ColumnSpacing = 4;
            r1.Padding = [4, 0, 4, 0];
            uilabel(r1, 'Text', 'X轴标题');
            app.XLabelEdit = uieditfield(r1, 'text', 'Value', 'Flow Time, s'); app.XLabelEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新X标题');
            uilabel(r1, 'Text', '左Y标题');
            app.YLabelEdit = uieditfield(r1, 'text', 'Value', 'Y Viscosity, Pa·s'); app.YLabelEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新左Y标题');
            uilabel(r1, 'Text', '右Y标题');
            app.YRightLabelEdit = uieditfield(r1, 'text', 'Value', 'Right Y'); app.YRightLabelEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新右Y标题');
            
            % 第二排：弹性开关列
            r2 = uigridlayout(app.BottomLayout, [1, 8]); r2.Layout.Row = 2;
            r2.ColumnWidth = {'1x', '1x', '1.25x', '1x', '1x', '1x', 60, 42};
            r2.ColumnSpacing = 6;
            r2.Padding = [6, 0, 6, 0];
            
            app.FontBoldChk = uicheckbox(r2, 'Text', '字体加粗', 'Value', false); app.FontBoldChk.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新字体加粗');
            app.TickOutChk = uicheckbox(r2, 'Text', '刻度向外', 'Value', false); app.TickOutChk.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新刻度方向'); 
            app.GridLineChk = uicheckbox(r2, 'Text', '背景网格线', 'Value', true); app.GridLineChk.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新网格线');
            app.LgdVisibleChk = uicheckbox(r2, 'Text', '显示图例', 'Value', true); app.LgdVisibleChk.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新图例显示');
            app.LgdBgChk = uicheckbox(r2, 'Text', '图例白底', 'Value', true); app.LgdBgChk.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新图例背景');
            app.LgdBorderChk = uicheckbox(r2, 'Text', '图例边框', 'Value', false); app.LgdBorderChk.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新图例边框');
            uilabel(r2, 'Text', '图例列数');
            app.LgdColsEdit = uieditfield(r2, 'numeric', 'Value', 2, 'Limits', [1 10], 'RoundFractionalValues', 'on'); app.LgdColsEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.UIChanged(src, event), '更新图例列数');
            
            % 第三排：滑块
            r3 = uigridlayout(app.BottomLayout, [1, 6]); r3.Layout.Row = 3;
            r3.ColumnWidth = {60, '1x', 50, 60, '1x', 50}; r3.Padding = [10, 0, 10, 0];
            
            uilabel(r3, 'Text', '图例水平', 'FontWeight', 'bold');
            app.LgdXSlider = uislider(r3, 'Limits', [0, 1], 'Value', 0.05);
            app.LgdXSlider.MajorTicks = [0, 0.2, 0.4, 0.6, 0.8, 1]; app.LgdXSlider.MinorTicks = 0:0.05:1;
            app.LgdXSlider.ValueChangingFcn = @(src, event) app.safeRun(@() app.LgdXSliderChanging(event), '拖动图例水平位置');
            app.LgdXEdit = uieditfield(r3, 'numeric', 'Value', 0.05, 'Limits', [0 1]); app.LgdXEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.LgdXEditChanged(src, event), '更新图例水平位置');
            
            uilabel(r3, 'Text', '图例垂直', 'FontWeight', 'bold');
            app.LgdYSlider = uislider(r3, 'Limits', [0, 1], 'Value', 0.85); 
            app.LgdYSlider.MajorTicks = [0, 0.2, 0.4, 0.6, 0.8, 1]; app.LgdYSlider.MinorTicks = 0:0.05:1;
            app.LgdYSlider.ValueChangingFcn = @(src, event) app.safeRun(@() app.LgdYSliderChanging(event), '拖动图例垂直位置');
            app.LgdYEdit = uieditfield(r3, 'numeric', 'Value', 0.85, 'Limits', [0 1]); app.LgdYEdit.ValueChangedFcn = @(src, event) app.safeRun(@() app.LgdYEditChanged(src, event), '更新图例垂直位置');

            statusPanel = uipanel(app.GridLayout, 'BorderType', 'none');
            statusPanel.Layout.Row = 2;
            statusPanel.Layout.Column = [1 3];
            statusGrid = uigridlayout(statusPanel, [1 2]);
            statusGrid.ColumnWidth = {'1x', 300};
            statusGrid.Padding = [6 0 6 0];
            app.StatusLabel = uilabel(statusGrid, 'Text', '状态：等待操作 | 错误日志：Documents\\LineAnimationAppLogs\\LineAnimationApp_error.log', 'FontColor', [0.35 0.35 0.35]);
            authText = '作者：ZYY        邮箱：zhangyiye1860@163.com';
            app.AuthorLabel = uilabel(statusGrid, 'Text', authText, 'HorizontalAlignment', 'right', 'FontSize', 10, 'FontColor', [0.45 0.45 0.45]);
            app.syncAxisStyleEnable();
            app.UIAxes.Box = 'off';
            app.UIAxes.XAxisLocation = 'bottom';
            xlabel(app.UIAxes, app.XLabelEdit.Value);
            ylabel(app.UIAxes, app.YLabelEdit.Value);
            app.drawFrameBorder(app.UIAxes, 1);
        end
    end

    methods (Access = public)
        function app = LineAnimationApp()
            createComponents(app); app.loadSettings(); app.UIFigure.Visible = 'on';
        end
    end
end

function out = fastif(condition, true_val, false_val)
    if condition, out = true_val; else, out = false_val; end
end
