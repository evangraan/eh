class MockMailer
  attr_accessor :e
  attr_accessor :msg

  def handle(e, msg)
    @e = e
    @msg = msg
  end
end