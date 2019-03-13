classdef waveFunction < handle
    properties(SetAccess = protected, GetAccess = public)
       T = 2*pi; % period
       f = 1/(2*pi); %frequency
       A = 1; %amplitude
       type = 1; % 1: sin; 2: rectangular; 3: triangular; 4: sawtooth; 5 full-rectified 
       DCoffset = 0;
       functionHandle;
       omega = 1;
    end
    properties(SetAccess = protected, GetAccess = public, Hidden)
        sinf; 
        rectf;
        trigf;
        sawtf;
        fullrectf;
        rects;
        trigs;
        sawts;
        fullrects;
        %  HARD  Add a ripple rectified wave with constant capacitace of 5
        %microFarads: Needs piecewise equation assembly and conditions 
        %  MED  Add a way to layer in more functions on top of each other:
        %add conditionals to app functions and a GUI interface 
        piano;
        funcArr;
        keyArr;
        defaultFunctionMap;
    end

    methods
        %Constructor for waveFunction
        function obj = waveFunction(type, freqency, amplitude, DCoffset)
            % Generates a wave function based on inputs
            % waveFunction(type, freqency, amplitude, DC offset)
            % Valid numbers of inputs: 0-4
            % Types are as follows: 
            % 1: sin;
            % 2: rectangular;
            % 3: triangular;
            % 4: sawtooth;
            % 5: full-rectified;
            % 7: series-based rectangular;
            % 8: series-based triangular;
            % 9: series-based sawtooth;
            % 10: series-based full-rectified;
            % type function_handle: any single variable;
            
            %init functions
            obj.sinf = @(t) obj.DCoffset + obj.A.*sin(obj.omega.*t); 
            obj.rectf = @(t) obj.DCoffset + (obj.A/2)+(obj.A/2).*sign(sin(obj.omega.*(t+(pi/2))));
            obj.trigf = @(t) obj.DCoffset + (1/2)+(2.*obj.A/obj.T).*(abs(mod(t, obj.T)-(obj.T/2))-(obj.T/4));
            obj.sawtf = @(t) obj.DCoffset + (2.*obj.A/pi).*atan(cot((t.*pi)/obj.T));
            obj.fullrectf = @(t) obj.DCoffset + obj.A.*abs(sin(obj.omega.*t/2));
            obj.piano = @(t)(-1/4)*sin(obj.f*3*pi*t)+(1/4)*sin(obj.f*t*pi)+cos(obj.f*t*pi);
            obj.rects = @(t, n) (2*obj.A/pi).*(((sin((2.*n-1).*obj.omega.*(t+(pi/2))))./(2.*n-1)));
            obj.trigs = @(t, n) (4*obj.A/(pi^2)).*((cos((2.*n-1).*obj.omega.*t))./( (2.*n-1).^2 ));
            obj.sawts = @(t, n) (obj.A/pi).*((sin(n.*obj.omega.*t) )./( n ));
            obj.fullrects = @(t, n) -(4*obj.A/pi).*((cos(n.*obj.omega.*t))./(4.*(n.^2)-1));
            
            %function map
            obj.funcArr = {obj.sinf, obj.rectf, obj.trigf, obj.sawtf, obj.fullrectf, obj.piano, obj.rects, obj.trigs, obj.sawts, obj.fullrects};
            obj.keyArr = 1:length(obj.funcArr);
            obj.defaultFunctionMap = containers.Map(obj.keyArr, obj.funcArr);
            %type=>map
            obj.functionHandle = obj.defaultFunctionMap(obj.type);
            
            
            %input scrubbers
            function [] = typeScrub()
                if isnumeric(type)
                    if type > 10 || type < 0
                        error("Error. Input is not a valid function key.");
                    elseif type < 7
                        obj.type = type;
                        obj.functionHandle = obj.defaultFunctionMap(type);
                    else
                        obj.type = {type};
                        obj.functionHandle = obj.defaultFunctionMap(type);
                    end
                elseif isa(type,'function_handle')
                    obj.type = 'Custom';
                    obj.functionHandle = type; 
                else
                    error("Error. Input is not a valid function key or handle.");
                end
            end
            
            %init properties
            switch nargin
                case 0
                    fprintf("Generating sine wave with period 2pi and amplitude 1.\n");
                case 1
                    typeScrub();
                    fprintf("Generating wave of specified type with period 2pi, and amplitude 1.\n");
                case 2
                    typeScrub();
                    obj.f = freqency;
                    fprintf("Generating wave of specified type and frequency with amplitude 1.\n");
                case 3
                    obj.f = freqency;
                    obj.A = amplitude;
                    typeScrub();
                    fprintf("Generating wave of specified type, frequency, and amplitude.\n");
                case 4
                    obj.f = freqency;
                    obj.A = amplitude;
                    typeScrub();
                    obj.DCoffset = DCoffset;
                    fprintf("Generating wave of specified type, frequency, amplitude, and DC offset.\n");
                otherwise
                    error("Error. Invalid number of arguments in constructor function.");
            end
            obj.T = 1/obj.f;
            obj.omega = 2*pi/obj.T;
        end
        
        %plot the function
        function [] = plotf(obj, interval)
            % Plots the wave function
            % plotf(interval) where interval is the displayed x-axis range
            if nargin == 1
                interval = [0,2*pi];
            end
            
            fprintf("Processing...\n");
            fplot(obj.functionHandle, interval);
            fprintf("Calculating waveform...\nThis may take a very long time.\n");
        end
        function [] = plotfApp(obj, ax)
            % Plots the wave function
            % plotf(interval) where interval is the displayed x-axis range
            
            fprintf("Processing...\n");
            fplot(ax, obj.functionHandle);
            fprintf("Calculating waveform...\nThis may take a very long time.\n");
        end
        function [] = seriesplot(obj, ax, intervalStart, intervalEnd, endIdx)
            % Plots series functions
            % seriesplot(intervalStart, intervalEnd, endIdx)
            types = obj.type{1};
            xArr = intervalStart:0.01:intervalEnd;
            seriesSum = 0;
            yArr = xArr;
            idx = 1;
            for x = xArr %the creation of an array of points
                for y = 1:endIdx %the series summation
                    seriesSum = seriesSum + obj.functionHandle(x, y);
                end
                yArr(idx) = seriesSum;
                idx = idx+1;
                seriesSum = 0;
            end
            if types == 7 || types == 8 || types == 9 || types == 10
                yArr = obj.DCoffset + (obj.A/2) + yArr;
            end
            splinein = intervalStart:0.001:intervalEnd;
            splineout = spline(xArr, yArr, splinein);
            plot(ax, splinein, splineout);
        end
        %functions to set values directly
        function obj = setAmp(obj, amplitude)
            %Sets the amplitude to the input value
            obj.A = abs(amplitude);
        end
        function obj = setFreq(obj, freq)
            %Sets the frequency to the input value
            %Also changes related values (period and omega)
            obj.f = freq;
            obj.T = 1/obj.f;
            obj.omega = 2*pi/obj.T;
        end
        function obj = setPeriod(obj, period)
            %Sets the period to the input value
            %Also changes related values (frequency and omega)
            obj.T = period;
            obj.f = 1/obj.T;
            obj.omega = 2*pi/obj.T;
        end
        function obj = setAngularFreq(obj, omega)
            %Sets the angular frequency to the input value
            %Also changes related values (frequency and period)
            obj.omega = omega;
            obj.f = obj.omega/(2*pi);
            obj.T = 1/obj.f;
        end
        function obj = setDCoffset(obj, offset)
            %Sets the DC offset to the input value
            obj.DCoffset = offset;
        end
        function obj = setFunction(obj, funcHandle)
            %Changes the function property to the function represented by
            %the handle inputed. If a valid function type number is input,
            %that value will be ued to set the handle and type instead.
            % Types are as follows: 
            % 1: sin;
            % 2: rectangular;
            % 3: triangular;
            % 4: sawtooth;
            % 5: full-rectified;
            % 7: series-based rectangular;
            % 8: series-based triangular;
            % 9: series-based sawtooth;
            % 10: series-based full-rectified;
            %Variables available:
            %   obj.A: amplitude
            %   obj.f: frequency
            %   obj.omega: angular frequency
            %   obj.T: period
            %   obj.DCoffset: DC offset
            
            if isa(funcHandle, 'char')
                funcHandle = str2double(funcHandle);
            end
            if isnumeric(funcHandle)
                if funcHandle > 10 || funcHandle < 0
                    error("Error. Input is not a valid function key.");
                elseif funcHandle < 7
                    obj.type = funcHandle;
                    obj.functionHandle = obj.defaultFunctionMap(funcHandle);
                else
                    obj.type = {funcHandle};
                    obj.functionHandle = obj.defaultFunctionMap(funcHandle);
                end
            elseif isa(funcHandle,'function_handle')
                obj.type = 'Custom';
                obj.functionHandle = funcHandle; 
            else
                error("Error. Input is not a valid function key or handle.");
            end
        end 
        
        %sound
        function [] = playSound(obj, duration)
            %Plays the current wave form at a sampling rate of 48000Hz (not
            %reliant on function frequency). A list of notes and their
            %frequencies can be found here:
            %http://www.sengpielaudio.com/calculator-notenames.htm 
                        
            duration = abs(duration);
            sampleRate = 48000;
            samples = linspace(0, duration, sampleRate*duration);
            
            if isa(obj.type, 'cell') == 1
                types = obj.type{1};
                xArr = samples;
                seriesSum = 0;
                yArr = xArr;
                idx = 1;
                
                for x = xArr %the creation of an array of points
                    for y = 1:20 %the series summation
                        seriesSum = seriesSum + obj.functionHandle(x, y);
                    end
                    yArr(idx) = seriesSum;
                    idx = idx+1;
                    seriesSum = 0;
                end
                
                if types == 7 || types == 8 || types == 9 || types == 10
                    yArr = obj.DCoffset + (obj.A/2) + yArr;
                end
                
                splinein = samples;
                audioArr = spline(xArr, yArr, splinein);
            else
                audioArr = obj.functionHandle(samples(:));
            end
            
            sound(audioArr, sampleRate);
        end
    end
    methods(Hidden)
        function [] = playPiano(obj, holdDur) 
            %WIP
            holdDur = abs(holdDur);
            sampleRate = 48000;
            ringLen = 0.4;
            noteDur = ringLen + holdDur;
            
            samples = linspace(0, noteDur, sampleRate*noteDur);
            audioArr = obj.functionHandle(samples(:));
            
            fadeFactor = linspace(1,0.001,ringLen*sampleRate)';
            endAudio = audioArr((end-ringLen*sampleRate)+1:end);
            fadeAudio = endAudio.*fadeFactor;
            beginAudio = audioArr(1:(end-ringLen*sampleRate));
            
            audioArr = [beginAudio', fadeAudio'];
            sound(audioArr, sampleRate);
        end
    end
end