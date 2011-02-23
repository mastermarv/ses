class TestSolrMulticore

  def setup
    system "../bin/ses-apache-solr install"
    system "../bin/ses-apache-solr create_core CORE=core0"
    system "../bin/ses-apache-solr create_core CORE=core1"
    system "../bin/ses-apache-solr start"
  end


  def teardown
    system "../bin/ses-apache-solr stop"
  end

end

