terraform {
  backend "s3" {
    bucket         = "new-terraform-backend"
    key            = "terraform.tfstate"
    region         =  "ap-south-1"
    encrypt        = false
    dynamodb_table = "lockingtable-teraa"
  }
}