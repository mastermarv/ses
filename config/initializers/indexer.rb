Infopark::SES::Indexer.index_fields do |obj|
  {:id => obj.id, :name => obj.name, :path => obj.path, :body => obj.body}
end
