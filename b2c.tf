## AAD B2C:-
resource "azurerm_aadb2c_directory" "Az_B2c" {
  country_code            = var.b2c-country-code
  data_residency_location = var.b2c-data-loc
  display_name            = var.b2c-name
  domain_name            = "${var.b2c-name}.onmicrosoft.com"
  resource_group_name     = var.b2c-rg
  sku_name                = var.b2c-sku
}


