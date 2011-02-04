class TestSolrMulticore

  def setup
    system "../bin/ses-apache-solr install"
    system "rsync -av ~/apache-solr/example/solr/conf/ ~/apache-solr/example/multicore/core0/conf/"
    system "rsync -av ~/apache-solr/example/solr/conf/ ~/apache-solr/example/multicore/core1/conf/"
    system "../bin/ses-apache-solr start:multicore"
  end


  def teardown
    system "../bin/ses-apache-solr stop"
  end

end

