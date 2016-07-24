# Eh

The Error handler gem provides the following major functional support for error handling,
based on the ideas expressed in the Exceptional Ruby book by Avdi Grimm

o Wrapping of code blocks in exception handling logic, supporting retry, logging and exception consumption, as well as a list of handlers that can be injected

o Provision of fault tolerant logging that logs to configured logger(s), or to stderr should loggers be unavailable

o Capability to handle unhandled exceptions, log them, email them and either raise them again or convert them to system exit codes (listing of standard linux exit codes provided as constants)

The Error Handler gem allows the wrapping of arbitrary blocks of code in exception handling logic. Specifically, once an exception occurs:

o The block can be retried 'threshold' times, with a delay of 'delay' seconds in-between retries (EH::retry and EH::retry!)

o The exception can be logged to a single logger, or an array of loggers

o The exception can be re-raised (suppressed during retry, but logged, raised again after retry failure)

o The same functionality is available, with retry disabled (EH::run and EH::run!)

o The list of Linux system exit codes is also provided as EH::EX_<exit>

o Unhandled exceptions can be logged and emailed in main() using EH::report_unhandled()

o A list of handlers can be injected to do custom handling, such as email, roll-back, etc.

This gem was sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## Installation

Add this line to your application's Gemfile:

    gem 'eh'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install eh

## Usage

    require 'rubygems'
    require 'eh/eh'

-- Run code block with retry, logging and exception re-raise, specifying logger, number of
   times to retry, retry delay, and block arguments. Also call handle(exception, message) on
   the list of handlers provided

    def load_configuration(configuration_path)
        EH::retry!(:logger => [@simple_logger, @verbose_logger],
                  :message => "Could not parse YAML configuration",
                  :args => [configuration_path],
                  :threshold => 5,
                  :delay => 0.5,
                  :exception_filter => [RuntimeError, IOError],
                  :handlers => [EmailNotifier.new, ZabbixNotifier.new, AirbrakeNotifier.new]) do
            YAML.load(File.open(configuration_path))
        end
    end

-- Run code block with retry only on the exceptions listed, with the default threshold and delay

    def load_configuration(configuration_path, logger = nil)
        EH::retry!(:args => [configuration_path], :exceptions => [IOError, RuntimeError]) do
            YAML.load(File.open(configuration_path))
        end
    end

-- Run code block without retry, and swallowing all exceptions

    def load_configuration(configuration_path, logger = nil)
        EH::run(:args => [configuration_path]) do
            YAML.load(File.open(configuration_path))
        end
    end

Any combination of the following options are allowed, both with both flavours of run() and retry().

    :logger - log using the logger's error() method
    :message - log this message, with the exception appended
    :args - code block arguments
    :threshold - the number of execution attempts
    :delay - the number of seconds to delay between retries
    :handlers - an array of handlers that implement handle(exception, message)

Function descriptions:

run - Execute block, swallow all exceptions, no retry

run! - Execute block, re-raise exceptions, no retry

retry - Execute block, swallow all exceptions, retry

retry! - Execute block, re-raise exceptions, retry

Exception filters:

When :exception_filter is provided to retry!(), only the exceptions in the filter are retried. If retry fails, *all* exceptions are re-raised.

When :exception_filter is provided to retry(), only the exceptions in the filter are retried. If retry fails, exceptions are not re-raised.

When :exception_filter is provided to run!(), only the exceptions in the filter are logged, if a logger is provided. Filtered exceptions are *not* re-raised.

When :exception_filter is provided to run(), only the exceptions in the filter are logged, if a logger is provided. Exceptions are not re-raised.

All exceptions are passed to all handlers, regardless of exception filter. It is up to the handler to filter out exceptions it is not interested in.

Unhandled exceptions can be logged and emailed as follows:

    at_exit do
        EH::report_unhandled(logfile = "/var/log/myapp/crash.log", email = "ernstvangraan@gmail.com")
        exit EH::EX_CONFIG
    end

Please send feedback and comments to the authors at:

Ernst van Graan <ernstvangraan@gmail>

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
