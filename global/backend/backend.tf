# Using the bucket we created to store the state that manages the bucket itself
# Self-referential so we ensure we migrate state before attempting to destroy the bucket
terraform {
  backend "gcs" {
    bucket = "xamos-tfstate"
    prefix = "global/backend"
  }
}
