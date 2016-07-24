require "spec_helper"
require "eh/eh"
require "mock_logger"
require "mock_mailer"

describe ErrorHandler do
  before :each do
    @logger = MockLogger.new
    @mailer = MockMailer.new
  end

  context "When executing a block of code without retry" do
    describe "run" do
      it "should swallow all exceptions if asked to" do
        begin
          exception = nil
          EH::run(nil) do
            raise RuntimeError
          end
        rescue => e
          exception = e
        end
        expect(exception.nil?).to eq(true)
      end

      it "should not retry" do
        begin
          count = 0
          EH::run(:exception_filter => [RuntimeError], :args => [count]) do
            count += 1
            raise RuntimeError
          end
        rescue => e
        end
        expect(count).to eq(1)
      end

      it "should log the message specified with the exception appended, using the logger specified" do
        expect(@logger).to receive(:error).with("the message: RuntimeError")
        begin
          EH::run(:logger => @logger, :message => "the message") do
            raise RuntimeError
          end
        end
      end

      it "should inform all handlers specified of the message and exception" do
        expect(@mailer).to receive(:handle)
        @handler2 = MockMailer.new
        begin
          EH::run(:handlers => [@mailer, @handler2], :message => "the message") do
            raise RuntimeError
          end
        end

        expect(@handler2.e.class).to eq(RuntimeError)
        expect(@handler2.msg).to eq("the message: RuntimeError")
      end

      it "should inform a specified handler of the message and exception" do
        begin
          EH::run(:handlers => @mailer, :message => "the message") do
            raise RuntimeError
          end
        end

        expect(@mailer.e.class).to eq(RuntimeError)
        expect(@mailer.msg).to eq("the message: RuntimeError")
      end

      it "should log the message specified with the exception appended, if the exception is in :exception_filter, using the logger specified" do
        expect(@logger).to receive(:error).with("the message: RuntimeError")
        begin
          EH::run(:logger => @logger, :message => "the message", :exception_filter => [RuntimeError]) do
            raise RuntimeError
          end
        end
      end

      it "should not log, if :exception_filter is specified and the exception is not in :exception_filter" do
        expect(@logger).not_to receive(:error)
        begin
          EH::run(:logger => @logger, :message => "the message", :exception_filter => [RuntimeError]) do
            raise IOError
          end
        end
      end

      it "should log using the level specified" do
        expect(@logger).to receive(:warn).with("the message: RuntimeError")
        begin
          EH::run(:logger => @logger, :message => "the message", :level => EH::WARN) do
            raise RuntimeError
          end
        end
      end
    end

    describe "run!" do
      it "should re-raise all exceptions if asked to (no options provided)" do
        begin
          exception = nil
          EH::run!(nil) do
            raise RuntimeError
          end
        rescue => e
          exception = e
        end
        expect(exception.class).to eq(RuntimeError)
      end

      it "should re-raise all exceptions if asked to (no exception filter provided)" do
        begin
          exception = nil
          EH::run!(:exception_filer => nil) do
            raise RuntimeError
          end
        rescue => e
          exception = e
        end
        expect(exception.class).to eq(RuntimeError)
      end

      it "should re-raise all exceptions if asked to (empty exception filter provided)" do
        begin
          exception = nil
          EH::run!(:exception_filter => []) do
            raise RuntimeError
          end
        rescue => e
          exception = e
        end
        expect(exception.class).to eq(RuntimeError)
      end

      it "should not retry" do
        begin
          count = 0
          EH::run!(:exception_filter => [RuntimeError], :args => [count]) do
            count += 1
            raise RuntimeError
          end
        rescue => e
        end
        expect(count).to eq(1)
      end

      it "should log the message specified with the exception appended, using the logger specified" do
        expect(@logger).to receive(:error).with("the message: RuntimeError")
        begin
          EH::run!(:logger => @logger, :message => "the message") do
            raise RuntimeError
          end
        rescue => e
        end
      end

      it "should inform all handlers specified of the message and exception" do
        expect(@mailer).to receive(:handle)
        @handler2 = MockMailer.new
        begin
          EH::run(:handlers => [@mailer, @handler2], :message => "the message") do
            raise RuntimeError
          end
        rescue => e
        end

        expect(@handler2.e.class).to eq(RuntimeError)
        expect(@handler2.msg).to eq("the message: RuntimeError")
      end

      it "should inform a specified handler of the message and exception" do
        begin
          EH::run(:handlers => @mailer, :message => "the message") do
            raise RuntimeError
          end
        rescue => e
        end

        expect(@mailer.e.class).to eq(RuntimeError)
        expect(@mailer.msg).to eq("the message: RuntimeError")
      end

      it "should log the message specified with the exception appended, if the exception is in :exception_filter, using the logger specified" do
        expect(@logger).to receive(:error).with("the message: RuntimeError")
        begin
          EH::run!(:logger => @logger, :message => "the message", :exception_filter => [RuntimeError]) do
            raise RuntimeError
          end
        rescue => e
        end
      end

      it "should not log, if :exception_filter is specified and the exception is not in :exception_filter" do
        expect(@logger).not_to receive(:error)
        begin
          EH::run!(:logger => @logger, :message => "the message", :exception_filter => [RuntimeError]) do
            raise IOError
          end
        rescue => e
        end
      end

      it "should log using the level specified" do
        expect(@logger).to receive(:warn).with("the message: RuntimeError")
        begin
          EH::run!(:logger => @logger, :message => "the message", :level => EH::WARN) do
            raise RuntimeError
          end
        rescue => e
        end
      end
    end
  end

  context "When executing a block of code with retry" do
    describe "retry" do
      it "should swallow all exceptions if asked to" do
        begin
          exception = nil
          EH::retry(nil) do
            raise RuntimeError
          end
        rescue => e
          exception = e
        end
        expect(exception.nil?).to eq(true)
      end

      it "should retry" do
        begin
          count = 0
          EH::retry(:exception_filter => [RuntimeError], :args => [count]) do
            count += 1
            raise RuntimeError
          end
        end
        expect(count).to eq(3)
      end

      it "should return true if the code succeeds after retry" do
        begin
          count = 0
          result = EH::retry(:exception_filter => [RuntimeError], :args => [count]) do
            count += 1
            raise RuntimeError if count < 2
          end
        end
        expect(result).to eq(true)
      end

      it "should return false if the code does not succeed after retry" do
        begin
          result = EH::retry(:exception_filter => [RuntimeError]) do
            raise RuntimeError
          end
        end
        expect(result).to eq(false)
      end

      it "should attempt the number of retries specified in :threshold" do
        begin
          count = 0
          EH::retry(:exception_filter => [RuntimeError], :args => [count], :threshold => 5) do
            count += 1
            raise RuntimeError
          end
        end
        expect(count).to eq(5)
      end

      it "should delay between intervals as specified in :delay" do
        begin
          pre = Time.now
          EH::retry(:exception_filter => [RuntimeError], :delay => 0.1, :threshold => 6) do
            raise RuntimeError
          end
        end
        post = Time.now
        expect(post - pre > 0.6).to eq(true)
      end

      it "should log the message specified with the exception appended, using the logger specified" do
        expect(@logger).to receive(:error).with("the message: RuntimeError")
        begin
          EH::retry(:logger => @logger, :message => "the message") do
            raise RuntimeError
          end
        end
      end

      it "should inform all handlers specified of the message and exception" do
        expect(@mailer).to receive(:handle)
        @handler2 = MockMailer.new
        begin
          EH::run(:handlers => [@mailer, @handler2], :message => "the message") do
            raise RuntimeError
          end
        end

        expect(@handler2.e.class).to eq(RuntimeError)
        expect(@handler2.msg).to eq("the message: RuntimeError")
      end

      it "should inform a specified handler of the message and exception" do
        begin
          EH::run(:handlers => @mailer, :message => "the message") do
            raise RuntimeError
          end
        end

        expect(@mailer.e.class).to eq(RuntimeError)
        expect(@mailer.msg).to eq("the message: RuntimeError")
      end

      it "should log the message specified with the exception appended, if the exception is in :exception_filter, using the logger specified" do
        expect(@logger).to receive(:error).with("the message: RuntimeError")
        begin
          EH::retry(:logger => @logger, :message => "the message", :exception_filter => [RuntimeError]) do
            raise RuntimeError
          end
        end
      end

      it "should not log, if :exception_filter is specified and the exception is not in :exception_filter" do
        expect(@logger).not_to receive(:error)
        begin
          EH::retry(:logger => @logger, :message => "the message", :exception_filter => [RuntimeError]) do
            raise IOError
          end
        end
      end

      it "should log using the level specified" do
        expect(@logger).to receive(:warn).with("the message: RuntimeError")
        begin
          EH::retry(:logger => @logger, :message => "the message", :level => EH::WARN) do
            raise RuntimeError
          end
        end
      end
    end

    describe "retry!" do
      it "should re-raise all exceptions if asked to" do
        begin
          exception = nil
          EH::retry!(nil) do
            raise RuntimeError
          end
        rescue => e
          exception = e
        end
        expect(exception.class).to eq(RuntimeError)
      end

      it "should retry" do
        begin
          count = 0
          EH::retry!(:exception_filter => [RuntimeError], :args => [count]) do
            count += 1
            raise RuntimeError
          end
        rescue => e
        end
        expect(count).to eq(3)
      end

      it "should attempt the number of retries specified in :threshold" do
        begin
          count = 0
          EH::retry(:exception_filter => [RuntimeError], :args => [count], :threshold => 5) do
            count += 1
            raise RuntimeError
          end
        rescue => e
        end
        expect(count).to eq(5)
      end

      it "should delay between intervals as specified in :delay" do
        begin
          pre = Time.now
          EH::retry(:exception_filter => [RuntimeError], :delay => 0.1, :threshold => 6) do
            raise RuntimeError
          end
        rescue => e
        end
        post = Time.now
        expect(post - pre > 0.6).to eq(true)
      end

      it "should log the message specified with the exception appended, using the logger specified" do
        expect(@logger).to receive(:error).with("the message: RuntimeError")
        begin
          EH::retry!(:logger => @logger, :message => "the message") do
            raise RuntimeError
          end
        rescue => e
        end
      end

      it "should inform all handlers specified of the message and exception" do
        expect(@mailer).to receive(:handle)
        @handler2 = MockMailer.new
        begin
          EH::run(:handlers => [@mailer, @handler2], :message => "the message") do
            raise RuntimeError
          end
        rescue => e
        end

        expect(@handler2.e.class).to eq(RuntimeError)
        expect(@handler2.msg).to eq("the message: RuntimeError")
      end

      it "should inform a specified handler of the message and exception" do
        begin
          EH::run(:handlers => @mailer, :message => "the message") do
            raise RuntimeError
          end
        rescue => e
        end

        expect(@mailer.e.class).to eq(RuntimeError)
        expect(@mailer.msg).to eq("the message: RuntimeError")
      end

      it "should log the message specified with the exception appended, if the exception is in :exception_filter, using the logger specified" do
        expect(@logger).to receive(:error).with("the message: RuntimeError")
        begin
          EH::retry!(:logger => @logger, :message => "the message", :exception_filter => [RuntimeError]) do
            raise RuntimeError
          end
        rescue => e
        end
      end

      it "should not log, if :exception_filter is specified and the exception is not in :exception_filter" do
        expect(@logger).not_to receive(:error)
        begin
          EH::retry!(:logger => @logger, :message => "the message", :exception_filter => [RuntimeError]) do
            raise IOError
          end
        rescue => e
        end
      end

      it "should log using the level specified" do
        expect(@logger).to receive(:warn).with("the message: RuntimeError")
        begin
          EH::retry!(:logger => @logger, :message => "the message", :level => EH::WARN) do
            raise RuntimeError
          end
        rescue => e
        end
      end
    end
  end

  context "when asked to log" do
    it "should log to a single logger provided, with the message specified, at the level specified" do
      expect(@logger).to receive(:info).with("testing single logging")
      EH::log(@logger, "testing single logging", EH::INFO)
    end

    it "should log to a single logger provided, with the message specified, at the level specified" do
      @logger2 = MockLogger.new

      expect(@logger).to receive(:debug).with("testing single logging")
      expect(@logger2).to receive(:debug).with("testing single logging")
      EH::log([@logger, @logger2], "testing single logging", EH::DEBUG)
    end

    it "should log at all log levels" do
      expect(@logger).to receive(:info)
      EH::log(@logger, "info", EH::INFO)

      expect(@logger).to receive(:debug)
      EH::log(@logger, "debug", EH::DEBUG)

      expect(@logger).to receive(:error)
      EH::log(@logger, "error", EH::ERROR)

      expect(@logger).to receive(:warn)
      EH::log(@logger, "warn", EH::WARN)

      expect(@logger).to receive(:fatal)
      EH::log(@logger, "fatal", EH::FATAL)
    end

    it "should log using 'warn' if a nil single logger is provided" do
      expect(EH).to receive(:warn).with "fatal: fatal"

      EH::log(nil, "fatal", EH::FATAL)
    end

    it "should not log if nil is provided in a list of loggers, and 'warn' should not be called" do
      expect(@logger).to receive(:fatal).once().with "fatal"
      expect(EH).not_to receive(:warn)

      EH::log([nil, @logger], "fatal", EH::FATAL)
    end
  end
end
