Infopark::SES::Indexer.index_fields do |obj|
  version_present = obj.released?
  version_present = obj.released? || obj.edited? if Rails.env == "preview"
  if version_present && !obj.suppress_export? && obj.searchable?
    plain_body = Infopark::SES::Filter::text_via_solr_cell(obj, :fallback => '') if obj.generic?
    {
      :id => obj.id,
      :name => obj.name,
      :path => obj.path,
      :body => plain_body || obj.body,
      :valid_from => obj.valid_from.utc.iso8601,
      :valid_until => (obj.valid_until && obj.valid_until.utc.iso8601),
      :title => obj[:title],
    }
  end
end


# Multicore configuration:

# Infopark::SES::Indexer.collections = {
#   RailsConnector::CmsBaseModel.instance_name => "http://127.0.0.1:8983/solr/#{RailsConnector::CmsBaseModel.instance_name}_#{Rails.env}"
# }
#
# Infopark::SES::Indexer.collection_selection do |obj|
#   RailsConnector::CmsBaseModel.instance_name
# end
