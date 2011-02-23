Infopark::SES::Indexer.index_fields do |obj|
  if obj.released? && !obj.suppress_export? && !obj.image?
    plain_body = Infopark::SES::Filter::text_via_solr_cell(obj, :fallback => '') if obj.generic?
    {
      :id => obj.id,
      :name => obj.name,
      :path => obj.path,
      :body => plain_body || obj.body,
      :valid_from => obj.valid_from.to_iso,
      :valid_until => obj.valid_until.try(:to_iso),
    }
  end
end


# Multicore configuration:

# Infopark::SES::Indexer.collections = {
#   "de" => 'http://127.0.0.1:8983/solr/de',
#   "en" => 'http://127.0.0.1:8983/solr/en',
# }
#
# Infopark::SES::Indexer.collection_selection do |obj|
#   language_path_component = obj.path.split("/", 3)[1]
#   [language_path_component] & %w(de en)
# end
