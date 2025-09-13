region          = "eu-west-1"
environment     = "production"
workspace_alias = "amp-demo"

# Disable all optional features for minimal setup
enable_alertmanager      = true
enable_recording_rules   = true
enable_high_availability = false
create_default_rules     = false

# Basic  scraping settings
scrape_interval = "60s" # Less frequent scraping