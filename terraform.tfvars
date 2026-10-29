region      = "ap-south-1"
project     = "webapp"
environment = "dev"
vpc_cidr    = "10.0.0.0/16"
az_count    = 2

instance_type        = "t3.micro"
asg_min_size         = 2
asg_desired_capacity = 2
asg_max_size         = 4

db_instance_class = "db.t3.micro"
db_username       = "appadmin"
