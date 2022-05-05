variable "B2C_NAME" {
  type        = string
  description = "list of all the AAD B2C to be created"
}

variable "b2c-country-code" {
  type        = string
  description = "Country Code of B2C"
}

variable "b2c-data-loc" {
  type        = string
  description = "Data Residency Location of B2C"
}

variable "b2c-rg" {
  type        = string
  description = "Resource Group of B2C"
}

variable "b2c-sku" {
  type        = string
  description = "Resource Group of B2C"
}