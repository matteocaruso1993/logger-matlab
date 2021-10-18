classdef Logger < handle
    %======================================================================
    % A simple and helpful logger MATLAB based class. The logger can
    %selectively print the log messages into the command window and in
    %log.log file.
    % The logger also display information on the system time at which it
    % has been called; moreover it implements a basic function call stack
    % which enables to navigate easily to the function that has called the
    % logger.
    %
    %levels: DEBUG, INFO, LOG, WARNING, ERROR, FATAL
    %
    %Basic Usage:
    %   l = Logger();
    %   l.info('Hello World');
    %
    %======================================================================
    %author: Matteo Caruso
    %email: matteo.caruso@phd.units.it
    
    
    properties (Access = private)
        debug_level = 0;
        info_level = 1;
        log_level = 2;
        warning_level = 3;
        error_level = 4;
        fatal_level = 5;
        cur_level = NaN;
        skip_entries = 3;
        writeToFile;
        displayToWindow;
        valid_levels;
    end
    
    methods
        function obj = Logger(varargin)
            %Class constructor
            p = inputParser;
            validateLogical = @(x) islogical(x);
            validateString = @(x) isstring(x) || @(x) ischar(x);
            validateLevels = @(x) validateInLevel(x);
            
            addOptional(p,'log2file',true, validateLogical);
            addOptional(p,'log2command',true,validateLogical);
            addOptional(p,'showLevels',[0,1,2,3,4,5],validateLevels);
            
            parse(p,varargin{:});
            
            a = p.Results;
            assignin('base','a',a);
            
            obj.enableFileLogging(a.log2file);
            obj.enableCommandWindowLogging(a.log2command);
            obj.filterLevels(a.showLevels);
            
            if ~exist('log','dir')
                mkdir('log');
                fclose(fopen('log/log.log', 'w'));
            else
                if ~exist('log/log.log','file')
                    fclose(fopen('log/log.log', 'w'));
                end
            end
            
            
            
        end
        
        
        function debug(obj,message)
            %Debug method 
            obj.cur_level = obj.debug_level;
            obj.log(message);
        end
        
        function info(obj,message)
            %Info method
            obj.cur_level = obj.info_level;
            obj.log(message);
        end
        
        function logging(obj,message)
            %Logging method
            obj.cur_level = obj.log_level;
            obj.log(message);
        end
        
        function warning(obj,message)
            %Warning method
            obj.cur_level = obj.warning_level;
            obj.log(message);
        end
        
        function error(obj,message)
            %Error method
            obj.cur_level = obj.error_level;
            obj.log(message);
        end
        
        function fatal(obj,message)
            %Fatal method
            obj.cur_level = obj.fatal_level;
            obj.log(message);
        end
        
        function enableFileLogging(obj, flag)
            %Method to enable/disable the file logging 
            if islogical(flag)
                obj.writeToFile = flag;
            end
        end
        
        function enableCommandWindowLogging(obj, flag)
            %Method to enable/disable the file logging
            if islogical(flag)
                obj.displayToWindow = flag;
            end
        end
        
        function filterLevels(obj,levels)
            %Method to filter the messages we want to display or write to
            %file
            if isstring(levels) || ischar(levels)
                if strcmp(levels,'all')
                    obj.valid_levels = [1,2,3,4,5];
                elseif strcmp(levels,'none')
                    obj.valid_levels = [];
                end
            elseif isnumeric(levels)
                if ~isscalar(levels)
                    obj.valid_levels = levels;
                else
                    obj.valid_levels = [levels];
                end
            end
            
        end
            
        function zipLog(obj)
            %Method to zip the logs files
            obj.compressAndDistributeLog()
        end
        
    end
    
    methods (Access = private, Static)
        function h = getHeader()
            t = now;
            h = strcat('[',num2str(t),']');
        end
        
        function clearLog()
            fclose(fopen('log/log.log','w'));
        end
        
        function compressAndDistributeLog()
            t = datetime('now');
            zip(strcat('log-',datestr(t,'dd-mm-yy_HH-MM-SS'),'.zip'),'log');
        end
    end
    
    methods (Access = private)
        function msgType = getMessageType(obj)
            switch obj.cur_level
                case obj.debug_level
                    msgType = '[DEBUG]';
                case obj.info_level
                    msgType = '[INFO]';
                case obj.log_level
                    msgType = '[LOG]';
                case obj.warning_level
                    msgType = '[WARNING]';
                case obj.error_level
                    msgType = '[ERROR]';
                case obj.fatal_level
                    msgType = '[FATAL]';
            end
                    
                    
                
            
        end
        
        function [msg_out, file_v,line_v] = processStack(obj)
            st = dbstack;
            try
                file_v = st(1 + obj.skip_entries).file;
                line_v = st(1 + obj.skip_entries).line;
            catch
                %Logger called from cmd_window
                file_v = 'CommandWindow';
                line_v = 1;
            end
            msg_out = strcat(file_v, '.'," ",'Line:'," ",num2str(line_v),'.');
            
        end
        
        
        function log(obj, message)
            if ~any(obj.valid_levels(:) == obj.cur_level)
                return
            end
            h = obj.getHeader();
            msg_type = obj.getMessageType();
            [st,f,l] = obj.processStack();
            link_to_file = strcat('<a href=','"matlab: opentoline(which(''',f,'''),',num2str(l),')">',strcat(f," ",'Line:'," ",num2str(l),'.</a>'));
            message_to_log_file = sprintf('%s%s[%s] Message: %s\n',msg_type,h,st,message);
            
            if strcmp(f,'CommandWindow')
                message_to_log_window = sprintf('<strong>%s%s</strong><strong>[%s]</strong> Message: %s\n',msg_type,h,st,message);
            else
            message_to_log_window = sprintf('<strong>%s%s</strong><strong>[</strong>%s<strong>]</strong> Message: %s\n',msg_type,h,link_to_file,message);
            end
            
            
            if obj.displayToWindow
                fprintf(message_to_log_window);
            end
            
            if obj.writeToFile
                f = fopen('log/log.log','a');
                fwrite(f,message_to_log_file);
                fclose(f);
            end
        end
    end
end


function out = validateInLevel(in_array)
    if isnumeric(in_array)
        out = true;
    else
        if isstring(in_array) || ischar(in_array)
            if any(validatestring(in_array,{'all','none'}))
                out = true;
            else
                out = false;
            end
        else
            
            out = false;
        end
    end
end

