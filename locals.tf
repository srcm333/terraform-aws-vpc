locals {
    common_tags = {
        Project = var.project
        Environment = var.environment
        Terrafoem = "true"
        Name = local.common_name
    }
    common_name = "${var.project}-${var.environment}" # Roboshop-dev
    az_names = slice(data.aws_availability_zones.available.names, 0, 2) # here 2 is exclusive
}