class TestMQ

  def setup
    system "../bin/ses-apache-activemq install"
    system "../bin/ses-apache-activemq start"
  end

  def teardown
    system "../bin/ses-apache-activemq stop"
  end

end
