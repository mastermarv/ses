Infopark::SES::Indexer.index_fields do |obj|
  if obj.released?
    {:id => obj.id, :name => obj.name, :path => obj.path, :body => obj.body}
  end
end
