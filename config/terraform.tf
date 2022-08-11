terraform {
  cloud {
    hostname = "app.terraform.io"
    organization = "go-getweather"
    workspaces {
      name = "go-getweather"
    }
  }
}