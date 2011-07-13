class TestSolr

  def setup
    system "../bin/ses-apache-solr install"
    system "../bin/ses-apache-solr start"
  end


  def teardown
    system "../bin/ses-apache-solr stop; sleep 10; killall -9 java; true"
  end

end

