module ErrorHandler
  class EH
    EX_OK          = 0  unless defined? EX_OK; EX_OK.freeze
    EX_GENERAL     = 1  unless defined? EX_GENERAL; EX_GENERAL.freeze
    EX_BASE        = 64 unless defined? EX_BASE; EX_BASE.freeze        # base value for error messages
    EX_USAGE       = 64 unless defined? EX_USAGE; EX_USAGE.freeze       # command line usage error
    EX_DATAERR     = 65 unless defined? EX_DATAERR; EX_DATAERR.freeze     # data format error
    EX_NOINPUT     = 66 unless defined? EX_NOINPUT; EX_NOINPUT.freeze     # cannot open input
    EX_NOUSER      = 67 unless defined? EX_NOUSER; EX_NOUSER.freeze      # addressee unknown
    EX_NOHOST      = 68 unless defined? EX_NOHOST; EX_NOHOST.freeze      # host name unknown
    EX_UNAVAILABLE = 69 unless defined? EX_UNAVAILABLE; EX_UNAVAILABLE.freeze # service unavailable
    EX_SOFTWARE    = 70 unless defined? EX_SOFTWARE; EX_SOFTWARE.freeze    # internal software error
    EX_OSERR       = 71 unless defined? EX_OSERR; EX_OSERR.freeze       # system error (e.g., can't fork)
    EX_OSFILE      = 72 unless defined? EX_OSFILE; EX_OSFILE.freeze      # critical OS file missing
    EX_CANTCREAT   = 73 unless defined? EX_CANTCREAT; EX_CANTCREAT.freeze   #  /* can't create (user) output file
    EX_IOERR       = 74 unless defined? EX_IOERR; EX_IOERR.freeze       # input/output error
    EX_TEMPFAIL    = 75 unless defined? EX_TEMPFAIL; EX_TEMPFAIL.freeze    # temp failure; user is invited to retry
    EX_PROTOCOL    = 76 unless defined? EX_PROTOCOL; EX_PROTOCOL.freeze    # remote error in protocol
    EX_NOPERM      = 77 unless defined? EX_NOPERM; EX_NOPERM.freeze      # permission denied
    EX_CONFIG      = 78 unless defined? EX_CONFIG; EX_CONFIG.freeze      # configuration error

    ERROR = 'error'
    DEBUG = 'debug'
    INFO = 'info'
    WARN = 'warn'
    FATAL = 'fatal'

    def self.report_unhandled(logfile = nil, handlers = nil)
      if $!
        message = "Unhandled exception: #{$!}"
        warn message
        if not logfile.nil?
          open(logfile, 'a') { |f|
            f.puts message
          }
        end

        handle(handlers, $!, message) if not handlers.nil?
      end
    end

    def self.retry!(options, &block)
      opts = options || {}
      EH::retry_with_raise(opts, block)

    rescue => e
      raise e if opts.nil? == false and opts[:exception_filter] and not opts[:exception_filter].include? e.class

      msg = "#{opts[:message]}: #{e.message}"
      EH::log(opts[:logger], msg, EH::log_level(opts)) if opts.nil? == false and not opts[:logger].nil? and not opts[:message].nil?
      EH::handle(opts[:handlers], e, msg) if not opts[:handlers].nil?
      raise e
    end

    def self.retry(options, &block)
      opts = options || {}
      begin
        EH::retry_with_raise(opts, block)
        return true
      rescue => e
        msg = "#{opts[:message]}: #{e.message}"
        if not opts[:logger].nil?
          EH::log(opts[:logger], msg, EH::log_level(opts)) if opts[:exception_filter].nil? or opts[:exception_filter].include? e.class
        end
        EH::handle(opts[:handlers], e, msg) if not opts[:handlers].nil?
        return false
      end
    end

    def self.run!(options, &block)
      opts = options || {}
      block.call(EH::construct_args(opts))

    rescue => e
      msg = "#{opts[:message]}: #{e.message}"
      if not opts[:logger].nil?
        EH::log(opts[:logger], msg, EH::log_level(opts)) if opts[:exception_filter].nil? or opts[:exception_filter].include? e.class
      end
      EH::handle(opts[:handlers], e, msg) if not opts[:handlers].nil?

      raise e if opts.nil? == false and opts[:exception_filter] and not opts[:exception_filter].include? e.class
      raise e if opts.nil? == true or opts[:exception_filter].nil? == true or opts[:exception_filter] == []
    end

    def self.run(options, &block)
      opts = options || {}
      block.call(EH::construct_args(opts))

    rescue => e
      msg = "#{opts[:message]}: #{e.message}"
      if not opts[:logger].nil?
        EH::log(opts[:logger], msg, EH::log_level(opts)) if opts[:exception_filter].nil? or opts[:exception_filter].include? e.class
      end
      EH::handle(opts[:handlers], e, msg) if not opts[:handlers].nil?
    end

    def self.log(facilities, msg, msg_type)
      if facilities.is_a? Array
        EH::log_multiple_loggers(facilities, msg, msg_type)
      else
        EH::log_single_logger(facilities, msg, msg_type)
      end
    end

    def self.generate_log_id
      ms = Time.now
    end

    private

    def self.handle(handlers, e, msg)
      return if handlers.nil?
      if handlers.is_a? Array
        handlers.each do |handler|
          handler.handle(e, msg) if not handler.nil?
        end
      else
        handlers.handle(e, msg)
      end
    end

    def self.construct_args(opts)
      return nil if opts.nil?
      return nil if opts[:args].nil?
      opts[:args].join(' ')
    end

    def self.retry_with_raise(opts, block)
      retry_threshold = opts[:threshold] || 3
      delay = opts[:delay] || 0.2
      attempts = 0
      begin
        block.call(EH::construct_args(opts))
      rescue => e
        raise e if opts[:exception_filter] and not opts[:exception_filter].include? e.class

        attempts += 1
        sleep delay
        retry if attempts < retry_threshold
        raise e
      end
    end

    def self.log_single_logger(logger, msg, msg_type)
      if logger.nil?
        warn msg_type + ': ' + msg
      else
        self.log([logger], msg, msg_type)
      end
    end

    def self.log_multiple_loggers(loggers, msg, msg_type)
      loggers.each do |logger|
        next if logger.nil?
        logger.warn msg if msg_type == WARN
        logger.debug msg if msg_type == DEBUG
        logger.error msg if msg_type == ERROR
        logger.info msg if msg_type == INFO
        logger.fatal msg if msg_type == FATAL
      end
    end

    def self.log_level(opts)
      opts[:level] || EH::ERROR
    end
  end
end

EH = ErrorHandler::EH