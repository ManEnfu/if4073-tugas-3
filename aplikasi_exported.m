classdef aplikasi_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        BrowseImageButton              matlab.ui.control.Button
        SettingsPanel                  matlab.ui.container.Panel
        PreprocessMethodDropDown       matlab.ui.control.DropDown
        PreprocessMethodDropDownLabel  matlab.ui.control.Label
        V4Slider                       matlab.ui.control.Slider
        NLabel_2                       matlab.ui.control.Label
        V3Slider                       matlab.ui.control.Slider
        NLabel                         matlab.ui.control.Label
        V2Slider                       matlab.ui.control.Slider
        EdgeThresholdLabel             matlab.ui.control.Label
        V1Slider                       matlab.ui.control.Slider
        BlurLevelLabel                 matlab.ui.control.Label
        SegmentationMethodDropDown     matlab.ui.control.DropDown
        SegmentationMethodDropDownLabel  matlab.ui.control.Label
        EdgeDetectionMethodDropDown    matlab.ui.control.DropDown
        EdgeDetectionMethodDropDownLabel  matlab.ui.control.Label
        OutputPanel                    matlab.ui.container.Panel
        GridLayout2                    matlab.ui.container.GridLayout
        ImageBlur                      matlab.ui.control.Image
        ImageGray                      matlab.ui.control.Image
        ImageResult                    matlab.ui.control.Image
        ImageMask                      matlab.ui.control.Image
        ImageEdge                      matlab.ui.control.Image
        ImageSource                    matlab.ui.control.Image
    end

    
    properties (Access = private)
        CurrentImage
        GrayImage
        BlurImage
        EdgeImage
        MaskImage
        ResultImage
        Loaded = false
    end
    
    methods (Access = private)
        
        % Fungsi utama
        function Generate(app)
            if (app.Loaded)
                % Ubah gambar masukan menjadi grayscale
                app.GrayImage = rgb2gray(app.CurrentImage);
                app.ImageGray.ImageSource = cat(3, app.GrayImage, app.GrayImage, app.GrayImage);

                % Lakukan blurring untuk menghilangkan derau
                app.BlurImage = app.GenerateBlurImage(app.GrayImage, app.PreprocessMethodDropDown.Value, app.V1Slider.Value);
                app.ImageBlur.ImageSource = cat(3, app.BlurImage, app.BlurImage, app.BlurImage);

                % Buat gambar biner tepi dengan teknik deteksi tepi yang
                % dipilih
                app.EdgeImage = app.GenerateEdgeImage(app.BlurImage, app.EdgeDetectionMethodDropDown.Value, app.V2Slider.Value, app.V3Slider.Value);
                app.ImageEdge.ImageSource = cat(3, app.EdgeImage, app.EdgeImage, app.EdgeImage) * 255;
    
                % Buat gambar biner mask dengan teknik segmentasi (region
                % filling) yang dipilih
                app.MaskImage = app.GenerateMaskImage(app.EdgeImage, app.SegmentationMethodDropDown.Value, app.V4Slider.Value);
                app.ImageMask.ImageSource = cat(3, app.MaskImage, app.MaskImage, app.MaskImage) * 255;
    
                % Terapkan gambar biner mask pada gambar masukan
                app.ResultImage = app.CurrentImage .* app.MaskImage;
                app.ImageResult.ImageSource = app.ResultImage;
            end
        end

        % Fungsi blurring (pemrosesan awal)
        function result = GenerateBlurImage(~, aImage, aMethod, aLevel)
            if (aLevel > 0)
                switch aMethod

                    % Blurring dengan filter disk
                    case 'Disk Filter'
                        result = imfilter(aImage, fspecial('disk', aLevel), 'replicate');

                    % Blurring dengan filter gaussian
                    case 'Gaussian Filter'
                        result = imgaussfilt(aImage, aLevel);

                    otherwise
                        result = aImage;
                end
            else
                result = aImage;
            end
        end

        % Fungsi pembuatan gambar biner tepi
        function result = GenerateEdgeImage(~, aImage, aMethod, aThreshold, aNC)
            switch aMethod

                % Deteksi tepi dengan metode Laplace
                case 'Laplace'
                    % Filter
                    H = [0 1 0; 1 -4 1; 0 1 0];
                    result = uint8(convn(double(aImage), double(H), "same") > aThreshold);

                % Deteksi tepi dengan metode Laplacian of Gaussian
                case 'LoG'
                    % Ukuran filter
                    n = round(aNC);
                    % Standar deviasi
                    s = n/5;
                    r = (n-1) / 2;
                    X = repmat(-r:r, n, 1);
                    Y = repmat(transpose(-r:r), 1, n);
                    t = -(X.*X+Y.*Y)/(2.0*s*s);
                    H = (-1/(pi*s*s*s*s)) * ((1+t) .* exp(t));
                    % Geser nilai sehingga jumlah elemen nol
                    H = H - mean2(H);
                    result = uint8(convn(double(aImage), double(H), "same") > aThreshold);

                % Deteksi tepi dengan metode Sobel
                case 'Sobel'
                    c = round(aNC);
                    % Filter horizontal
                    Hx = [-1 0 1; -c 0 c; -1 0 1];
                    % Filter vertikal
                    Hy = [1 c 1; 0 0 0; -1 -c -1];
                    Jx = convn(double(aImage), double(Hx), "same");
                    Jy = convn(double(aImage), double(Hy), "same");
                    % Jumlahkan kedua hasil konvolusi
                    result = uint8(abs(Jx) + abs(Jy) > aThreshold);

                % Deteksi tepi dengan metode Prewitt
                case 'Prewitt'
                    % Filter horizontal
                    Hx = [-1 0 1; -1 0 1; -1 0 1];
                    % Filter vertikal
                    Hy = [1 1 1; 0 0 0; -1 -1 -1];
                    Jx = convn(double(aImage), double(Hx), "same");
                    Jy = convn(double(aImage), double(Hy), "same");
                    % Jumlahkan kedua hasil konvolusi
                    result = uint8(abs(Jx) + abs(Jy) > aThreshold);

                % Deteksi tepi dengan metode Roberts
                case 'Roberts'
                    Hx = [1 0; 0 -1];
                    Hy = [0 1; -1 0];
                    Jx = convn(double(aImage), double(Hx), "same");
                    Jy = convn(double(aImage), double(Hy), "same");
                    % Jumlahkan kedua hasil konvolusi
                    result = uint8(abs(Jx) + abs(Jy) > aThreshold);

                % Deteksi tepi dengan metode Canny
                case 'Canny'
                    result = edge(aImage, 'canny', aThreshold/255);

                otherwise
                    result = aImage;
            end
        end

        % Fungsi pembuatan gambar biner mask
        function result = GenerateMaskImage(~, aImage, aMethod, aThreshold)
            switch aMethod

                % Buat mask dengan metode 1, untuk gambar dengan banyak
                % tepi
                case 'Dilate-Thin-Fill-Erode'

                    % Bersihkan pixel-pixel pada tepi gambar
                    vImage = imclearborder(aImage);

                    % Lakukan dilatasi pada gambar supaya tepi-tepi menjadi
                    % terhubung, kemudian lakukan thinning supaya tepi yang
                    % terhubung kembali tipis
                    vImage = imdilate(vImage, strel('disk', round(aThreshold)));
                    vImage = bwmorph(vImage, 'thin', Inf);

                    % Isi daerah-daerah yang dikelilingi tepi terhubung
                    vImage = imfill(vImage, 'holes');

                    % Lakukan erosi pada gambar untuk menghilangkan
                    % tepi-tepi yang tidak mengelilingi daerah
                    vImage = imerode(vImage, strel('disk', 2));

                    % Ubah tipe data menjadi uint8
                    result = uint8(vImage);

                % Buat mask dengan metode 2, untuk gambar sederhana
                case 'Close-Fill-Erode'

                    % Bersihkan pixel-pixel pada tepi gambar
                    vImage = imclearborder(aImage);

                    % Lakukan operasi morphological closing pada gambar
                    % supaya tepi-tepi menjadi terhubung
                    vImage = imclose(vImage, strel('disk', round(aThreshold)));

                    % Isi daerah-daerah yang dikelilingi tepi terhubung
                    vImage = imfill(vImage, 8, 'holes');

                    % Lakukan erosi pada gambar untuk menghilangkan
                    % tepi-tepi yang tidak mengelilingi daerah
                    vImage = imerode(vImage, strel('disk', 2));

                    % Ubah tipe data menjadi uint8
                    result = uint8(vImage);
                    
                otherwise
                    result = uint8(ones([size(aImage, 1), size(aImage, 2)]));
            end
        end

        function ToggleSliders(app)
            switch app.EdgeDetectionMethodDropDown.Value
                case 'LoG'
                    app.V3Slider.Enable = 'on';
                case 'Sobel'
                    app.V3Slider.Enable = 'on';
                otherwise
                    app.V3Slider.Enable = 'off';
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.ToggleSliders();
        end

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
        % PreprocessMethodDropDown, SegmentationMethodDropDown, V1Slider, 
        % V2Slider, V3Slider, V4Slider
        function SegmentationMethodDropDownValueChanged(app, event)
            app.ToggleSliders();
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
            app.GridLayout.RowHeight = {'0.5x', '4.5x', '6x'};

            % Create OutputPanel
            app.OutputPanel = uipanel(app.GridLayout);
            app.OutputPanel.Title = 'Output';
            app.OutputPanel.Layout.Row = 3;
            app.OutputPanel.Layout.Column = 1;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.OutputPanel);
            app.GridLayout2.ColumnWidth = {'1x', '1x', '1x'};

            % Create ImageSource
            app.ImageSource = uiimage(app.GridLayout2);
            app.ImageSource.Layout.Row = 1;
            app.ImageSource.Layout.Column = 1;

            % Create ImageEdge
            app.ImageEdge = uiimage(app.GridLayout2);
            app.ImageEdge.Layout.Row = 2;
            app.ImageEdge.Layout.Column = 1;

            % Create ImageMask
            app.ImageMask = uiimage(app.GridLayout2);
            app.ImageMask.Layout.Row = 2;
            app.ImageMask.Layout.Column = 2;

            % Create ImageResult
            app.ImageResult = uiimage(app.GridLayout2);
            app.ImageResult.Layout.Row = 2;
            app.ImageResult.Layout.Column = 3;

            % Create ImageGray
            app.ImageGray = uiimage(app.GridLayout2);
            app.ImageGray.Layout.Row = 1;
            app.ImageGray.Layout.Column = 2;

            % Create ImageBlur
            app.ImageBlur = uiimage(app.GridLayout2);
            app.ImageBlur.Layout.Row = 1;
            app.ImageBlur.Layout.Column = 3;

            % Create SettingsPanel
            app.SettingsPanel = uipanel(app.GridLayout);
            app.SettingsPanel.Title = 'Settings';
            app.SettingsPanel.Layout.Row = 2;
            app.SettingsPanel.Layout.Column = 1;

            % Create EdgeDetectionMethodDropDownLabel
            app.EdgeDetectionMethodDropDownLabel = uilabel(app.SettingsPanel);
            app.EdgeDetectionMethodDropDownLabel.Position = [12 225 131 22];
            app.EdgeDetectionMethodDropDownLabel.Text = 'Edge Detection Method';

            % Create EdgeDetectionMethodDropDown
            app.EdgeDetectionMethodDropDown = uidropdown(app.SettingsPanel);
            app.EdgeDetectionMethodDropDown.Items = {'Laplace', 'LoG', 'Sobel', 'Prewitt', 'Roberts', 'Canny'};
            app.EdgeDetectionMethodDropDown.Editable = 'on';
            app.EdgeDetectionMethodDropDown.ValueChangedFcn = createCallbackFcn(app, @SegmentationMethodDropDownValueChanged, true);
            app.EdgeDetectionMethodDropDown.BackgroundColor = [1 1 1];
            app.EdgeDetectionMethodDropDown.Position = [162 225 587 22];
            app.EdgeDetectionMethodDropDown.Value = 'Canny';

            % Create SegmentationMethodDropDownLabel
            app.SegmentationMethodDropDownLabel = uilabel(app.SettingsPanel);
            app.SegmentationMethodDropDownLabel.Position = [12 195 123 22];
            app.SegmentationMethodDropDownLabel.Text = 'Segmentation Method';

            % Create SegmentationMethodDropDown
            app.SegmentationMethodDropDown = uidropdown(app.SettingsPanel);
            app.SegmentationMethodDropDown.Items = {'Dilate-Thin-Fill-Erode', 'Close-Fill-Erode'};
            app.SegmentationMethodDropDown.Editable = 'on';
            app.SegmentationMethodDropDown.ValueChangedFcn = createCallbackFcn(app, @SegmentationMethodDropDownValueChanged, true);
            app.SegmentationMethodDropDown.BackgroundColor = [1 1 1];
            app.SegmentationMethodDropDown.Position = [162 195 587 22];
            app.SegmentationMethodDropDown.Value = 'Close-Fill-Erode';

            % Create BlurLevelLabel
            app.BlurLevelLabel = uilabel(app.SettingsPanel);
            app.BlurLevelLabel.Position = [12 166 98 22];
            app.BlurLevelLabel.Text = 'Preprocess Level';

            % Create V1Slider
            app.V1Slider = uislider(app.SettingsPanel);
            app.V1Slider.Limits = [0 25];
            app.V1Slider.MajorTicks = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25];
            app.V1Slider.MajorTickLabels = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25'};
            app.V1Slider.ValueChangedFcn = createCallbackFcn(app, @SegmentationMethodDropDownValueChanged, true);
            app.V1Slider.MinorTicks = [];
            app.V1Slider.Position = [161 175 576 3];

            % Create EdgeThresholdLabel
            app.EdgeThresholdLabel = uilabel(app.SettingsPanel);
            app.EdgeThresholdLabel.Position = [12 124 90 22];
            app.EdgeThresholdLabel.Text = 'Edge Threshold';

            % Create V2Slider
            app.V2Slider = uislider(app.SettingsPanel);
            app.V2Slider.Limits = [0 255];
            app.V2Slider.ValueChangedFcn = createCallbackFcn(app, @SegmentationMethodDropDownValueChanged, true);
            app.V2Slider.MinorTicks = [];
            app.V2Slider.Position = [161 133 576 3];
            app.V2Slider.Value = 16;

            % Create NLabel
            app.NLabel = uilabel(app.SettingsPanel);
            app.NLabel.Position = [12 82 109 22];
            app.NLabel.Text = 'N (LoG) / C (Sobel)';

            % Create V3Slider
            app.V3Slider = uislider(app.SettingsPanel);
            app.V3Slider.Limits = [0 25];
            app.V3Slider.MajorTicks = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25];
            app.V3Slider.MajorTickLabels = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25'};
            app.V3Slider.ValueChangedFcn = createCallbackFcn(app, @SegmentationMethodDropDownValueChanged, true);
            app.V3Slider.MinorTicks = [];
            app.V3Slider.Position = [161 91 576 3];
            app.V3Slider.Value = 2;

            % Create NLabel_2
            app.NLabel_2 = uilabel(app.SettingsPanel);
            app.NLabel_2.Position = [12 40 136 22];
            app.NLabel_2.Text = 'Segmentation Threshold';

            % Create V4Slider
            app.V4Slider = uislider(app.SettingsPanel);
            app.V4Slider.ValueChangedFcn = createCallbackFcn(app, @SegmentationMethodDropDownValueChanged, true);
            app.V4Slider.MinorTicks = [];
            app.V4Slider.Position = [161 49 576 3];
            app.V4Slider.Value = 10;

            % Create PreprocessMethodDropDownLabel
            app.PreprocessMethodDropDownLabel = uilabel(app.SettingsPanel);
            app.PreprocessMethodDropDownLabel.Position = [12 258 110 22];
            app.PreprocessMethodDropDownLabel.Text = 'Preprocess Method';

            % Create PreprocessMethodDropDown
            app.PreprocessMethodDropDown = uidropdown(app.SettingsPanel);
            app.PreprocessMethodDropDown.Items = {'Gaussian Filter', 'Disk Filter'};
            app.PreprocessMethodDropDown.Editable = 'on';
            app.PreprocessMethodDropDown.ValueChangedFcn = createCallbackFcn(app, @SegmentationMethodDropDownValueChanged, true);
            app.PreprocessMethodDropDown.BackgroundColor = [1 1 1];
            app.PreprocessMethodDropDown.Position = [162 258 587 22];
            app.PreprocessMethodDropDown.Value = 'Gaussian Filter';

            % Create BrowseImageButton
            app.BrowseImageButton = uibutton(app.GridLayout, 'push');
            app.BrowseImageButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseImageButtonPushed, true);
            app.BrowseImageButton.Layout.Row = 1;
            app.BrowseImageButton.Layout.Column = 1;
            app.BrowseImageButton.Text = 'Browse Image';

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

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

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