Infopark::SES::Filter.verity_input_filter = {
  :bin_path => Dir.glob("#{ENV['HOME']}/*/instance/default/bin/IF").first,
  :cfg_path => Dir.glob("#{ENV['HOME']}/*/instance/default/config/IF.cfg.indexing").first,
  :timeout_seconds => 30
}