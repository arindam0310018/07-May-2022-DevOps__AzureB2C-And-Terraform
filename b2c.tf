## AAD B2C:-
resource "azurerm_aadb2c_directory" "Az_B2c" {
  country_code            = var.b2c-country-code
  data_residency_location = var.b2c-data-loc
  display_name            = var.B2C_NAME
  domain_name             = "${var.B2C_NAME}.onmicrosoft.com"
  resource_group_name     = var.b2c-rg
  sku_name                = var.b2c-sku
}


