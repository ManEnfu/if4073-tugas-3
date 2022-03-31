classdef aplikasi_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        OutputPanel                  matlab.ui.container.Panel
        GridLayout2                  matlab.ui.container.GridLayout
        ImageResult                  matlab.ui.control.Image
        ImageMask                    matlab.ui.control.Image
        ImageEdge                    matlab.ui.control.Image
        ImageSource                  matlab.ui.control.Image
        InputPanel                   matlab.ui.container.Panel
        V3Slider                     matlab.ui.control.Slider
        NLabel                       matlab.ui.control.Label
        V2Slider                     matlab.ui.control.Slider
        FillThresholdSlider_2Label   matlab.ui.control.Label
        V1Slider                     matlab.ui.control.Slider
        EdgeThresholdSliderLabel     matlab.ui.control.Label
        SegmentationMethodDropDown   matlab.ui.control.DropDown
        SegmentationMethodDropDownLabel  matlab.ui.control.Label
        EdgeDetectionMethodDropDown  matlab.ui.control.DropDown
        EdgeDetectionMethodDropDownLabel  matlab.ui.control.Label
        BrowseImageButton            matlab.ui.control.Button
    end

    
    properties (Access = private)
        CurrentImage
        EdgeImage
        MaskImage
        ResultImage
        Loaded = false
    end
    
    methods (Access = private)
        
        function Generate(app)
            if (app.Loaded)
                % Generate edge image
                app.EdgeImage = app.GenerateEdgeImage(rgb2gray(app.CurrentImage), app.EdgeDetectionMethodDropDown.Value, app.V1Slider.Value, app.V3Slider.Value);
                app.ImageEdge.ImageSource = cat(3, app.EdgeImage, app.EdgeImage, app.EdgeImage) * 255;
    
                % Generate mask image
                app.MaskImage = app.GenerateMaskImage(app.EdgeImage, app.SegmentationMethodDropDown.Value, app.V2Slider.Value);
                app.ImageMask.ImageSource = cat(3, app.MaskImage, app.MaskImage, app.MaskImage) * 255;
    
                % Apply mask to original image
                app.ResultImage = app.CurrentImage .* app.MaskImage;
                app.ImageResult.ImageSource = app.ResultImage;
            end
        end

        function result = GenerateEdgeImage(~, aImage, aMethod, aThreshold, aNC)
            switch aMethod
                case 'Laplace'
                    H = [0 1 0; 1 -4 1; 0 1 0];
                    result = uint8(convn(double(aImage), double(H), "same") > aThreshold);
                case 'LoG'
                    n = round(aNC);
                    s = n/5;
                    s = 2.0 * s * s;
                    r = (n-1) / 2;
                    X = repmat([-r:r], n, 1);
                    Y = repmat(transpose([-r:r]), 1, n);
                    H = 1/(s*pi) * exp(-(X.*X+Y.*Y)/s);
                    H = H / sum(sum(H));
                    L = [0 1 0; 1 -4 1; 0 1 0];
                    H = (convn(double(H), double(L), "same"));
                    result = uint8(convn(double(aImage), double(H), "same") > aThreshold);
                case 'Sobel'
                    c = round(aNC);
                    Hx = [-1 0 1; -c 0 c; -1 0 1];
                    Hy = [1 c 1; 0 0 0; -1 -c -1];
                    Jx = convn(double(aImage), double(Hx), "same");
                    Jy = convn(double(aImage), double(Hy), "same");
                    result = uint8(abs(Jx) + abs(Jy) > aThreshold);
                case 'Prewitt'
                    Hx = [-1 0 1; -1 0 1; -1 0 1];
                    Hy = [1 1 1; 0 0 0; -1 -1 -1];
                    Jx = convn(double(aImage), double(Hx), "same");
                    Jy = convn(double(aImage), double(Hy), "same");
                    result = uint8(abs(Jx) + abs(Jy) > aThreshold);
                case 'Roberts'
                    Hx = [1 0; 0 -1];
                    Hy = [0 1; -1 0];
                    Jx = convn(double(aImage), double(Hx), "same");
                    Jy = convn(double(aImage), double(Hy), "same");
                    result = uint8(abs(Jx) + abs(Jy) > aThreshold);
                case 'Canny'
                    result = edge(aImage, 'canny', aThreshold/255);
                otherwise
                    result = aImage;
            end
        end

        function result = GenerateMaskImage(~, aImage, aMethod, aThreshold)
            switch aMethod
                case 'Dilation Fill'
                    vStructuringElement = strel('disk',round(aThreshold));
                    vImage = imdilate(aImage, vStructuringElement);
                    vImage = imerode(vImage, vStructuringElement);
                    result = uint8(imfill(vImage,'holes'));
                otherwise
                    result = uint8(ones([size(aImage, 1), size(aImage, 2)]));
            end
        end

        function EnableVariables(app)
            switch app.EdgeDetectionMethodDropDown.Value
                case 'LoG'
                    app.V3Slider.Enable = 'on';
                case 'Sobel'
                    app.V3Slider.Enable = 'on';
                otherwise
                    app.V3Slider.Enable = 'off';
            end

            switch app.SegmentationMethodDropDown.Value
                case 'Dilation Fill'
                    app.V2Slider.Enable = 'on';
                otherwise
                    app.V2Slider.Enable = 'off';
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: BrowseImageButton
        function BrowseImageButtonPushed(app, event)
            [file,path] = uigetfile({'*.png;*.jpg;*.jpeg','Images'});
            if (file ~= 0)
                app.CurrentImage = imread(fullfile(path,file));
                app.Loaded = true;
                app.ImageSource.ImageSource = app.CurrentImage;
                app.Generate();
            end
        end

        % Value changed function: EdgeDetectionMethodDropDown, 
        % SegmentationMethodDropDown, V1Slider, V2Slider, V3Slider
        function SegmentationMethodDropDownValueChanged(app, event)
            app.EnableVariables();
            app.Generate();
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 781 798];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'3.5x', '6.5x'};

            % Create InputPanel
            app.InputPanel = uipanel(app.GridLayout);
            app.InputPanel.Title = 'Input';
            app.InputPanel.Layout.Row = 1;
            app.InputPanel.Layout.Column = 1;

            % Create BrowseImageButton
            app.BrowseImageButton = uibutton(app.InputPanel, 'push');
            app.BrowseImageButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseImageButtonPushed, true);
            app.BrowseImageButton.Position = [12 217 737 22];
            app.BrowseImageButton.Text = 'Browse Image';

            % Create EdgeDetectionMethodDropDownLabel
            app.EdgeDetectionMethodDropDownLabel = uilabel(app.InputPanel);
            app.EdgeDetectionMethodDropDownLabel.Position = [12 184 131 22];
            app.EdgeDetectionMethodDropDownLabel.Text = 'Edge Detection Method';

            % Create EdgeDetectionMethodDropDown
            app.EdgeDetectionMethodDropDown = uidropdown(app.InputPanel);
            app.EdgeDetectionMethodDropDown.Items = {'Laplace', 'LoG', 'Sobel', 'Prewitt', 'Roberts', 'Canny'};
            app.EdgeDetectionMethodDropDown.Editable = 'on';
            app.EdgeDetectionMethodDropDown.ValueChangedFcn = createCallbackFcn(app, @SegmentationMethodDropDownValueChanged, true);
            app.EdgeDetectionMethodDropDown.BackgroundColor = [1 1 1];
            app.EdgeDetectionMethodDropDown.Position = [162 184 587 22];
            app.EdgeDetectionMethodDropDown.Value = 'Laplace';

            % Create SegmentationMethodDropDownLabel
            app.SegmentationMethodDropDownLabel = uilabel(app.InputPanel);
            app.SegmentationMethodDropDownLabel.Position = [12 154 123 22];
            app.SegmentationMethodDropDownLabel.Text = 'Segmentation Method';

            % Create SegmentationMethodDropDown
            app.SegmentationMethodDropDown = uidropdown(app.InputPanel);
            app.SegmentationMethodDropDown.Items = {'Dilation Fill'};
            app.SegmentationMethodDropDown.Editable = 'on';
            app.SegmentationMethodDropDown.ValueChangedFcn = createCallbackFcn(app, @SegmentationMethodDropDownValueChanged, true);
            app.SegmentationMethodDropDown.BackgroundColor = [1 1 1];
            app.SegmentationMethodDropDown.Position = [162 154 587 22];
            app.SegmentationMethodDropDown.Value = 'Dilation Fill';

            % Create EdgeThresholdSliderLabel
            app.EdgeThresholdSliderLabel = uilabel(app.InputPanel);
            app.EdgeThresholdSliderLabel.Position = [13 125 90 22];
            app.EdgeThresholdSliderLabel.Text = 'Edge Threshold';

            % Create V1Slider
            app.V1Slider = uislider(app.InputPanel);
            app.V1Slider.Limits = [0 255];
            app.V1Slider.ValueChangedFcn = createCallbackFcn(app, @SegmentationMethodDropDownValueChanged, true);
            app.V1Slider.Position = [162 134 576 3];
            app.V1Slider.Value = 12;

            % Create FillThresholdSlider_2Label
            app.FillThresholdSlider_2Label = uilabel(app.InputPanel);
            app.FillThresholdSlider_2Label.Position = [13 83 77 22];
            app.FillThresholdSlider_2Label.Text = 'Fill Threshold';

            % Create V2Slider
            app.V2Slider = uislider(app.InputPanel);
            app.V2Slider.Limits = [0 125];
            app.V2Slider.ValueChangedFcn = createCallbackFcn(app, @SegmentationMethodDropDownValueChanged, true);
            app.V2Slider.Enable = 'off';
            app.V2Slider.Position = [162 92 576 3];
            app.V2Slider.Value = 4;

            % Create NLabel
            app.NLabel = uilabel(app.InputPanel);
            app.NLabel.Position = [13 41 109 22];
            app.NLabel.Text = 'N (LoG) / C (Sobel)';

            % Create V3Slider
            app.V3Slider = uislider(app.InputPanel);
            app.V3Slider.Limits = [0 50];
            app.V3Slider.ValueChangedFcn = createCallbackFcn(app, @SegmentationMethodDropDownValueChanged, true);
            app.V3Slider.Enable = 'off';
            app.V3Slider.Position = [162 50 576 3];
            app.V3Slider.Value = 1;

            % Create OutputPanel
            app.OutputPanel = uipanel(app.GridLayout);
            app.OutputPanel.Title = 'Output';
            app.OutputPanel.Layout.Row = 2;
            app.OutputPanel.Layout.Column = 1;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.OutputPanel);

            % Create ImageSource
            app.ImageSource = uiimage(app.GridLayout2);
            app.ImageSource.Layout.Row = 1;
            app.ImageSource.Layout.Column = 1;

            % Create ImageEdge
            app.ImageEdge = uiimage(app.GridLayout2);
            app.ImageEdge.Layout.Row = 1;
            app.ImageEdge.Layout.Column = 2;

            % Create ImageMask
            app.ImageMask = uiimage(app.GridLayout2);
            app.ImageMask.Layout.Row = 2;
            app.ImageMask.Layout.Column = 1;

            % Create ImageResult
            app.ImageResult = uiimage(app.GridLayout2);
            app.ImageResult.Layout.Row = 2;
            app.ImageResult.Layout.Column = 2;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = aplikasi_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end