module "network" {
  source               = "./modules/network"
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
}

resource "aws_db_subnet_group" "main" {
  name       = "aurora-subnet-group"
  subnet_ids = [for subnet in module.network.private_subnets : subnet.id]
}

resource "aws_rds_cluster" "main" {
  cluster_identifier     = "bjgomes-aurora-serverless"
  engine                 = "aurora-mysql"
  engine_mode            = "provisioned"
  engine_version         = "8.0"
  database_name          = "wordpress"
  master_username        = "admin"
  master_password        = "password1234"
  vpc_security_group_ids = [module.network.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  skip_final_snapshot    = true


  serverlessv2_scaling_configuration {
    max_capacity = 2.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "main" {
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
  tags = {
    Name = "bjgomes-aurora-serverless-instance"
  }
  depends_on = [module.network.aws_nat_gateway]
}

resource "aws_lb" "main" {
  load_balancer_type = "application"
  name               = "bjgomes-ALB"
  security_groups    = [module.network.security_group_id]
  subnets            = [for subnet in module.network.public_subnets : subnet.id]

}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_target_group" "main" {
  name     = "bjgomes-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id
}



resource "aws_launch_template" "main" {
  name = "bjgomes-launch-template"

  iam_instance_profile {
    name = "SSM"
  }

  image_id = data.aws_ami.ubuntu.id

  instance_type = "t4g.medium"

  key_name = "bjgomes"

  vpc_security_group_ids = [module.network.security_group_id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "terraform"
      Env  = "Dev"
    }
  }

  user_data = base64encode(<<EOF
#!/bin/bash

apt-get update -y
apt-get upgrade -y

apt-get install -y apache2 mysql-client php php-mysql libapache2-mod-php php-cli php-curl php-gd php-mbstring php-xml php-xmlrpc

systemctl restart apache2

cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xf latest.tar.gz
rm latest.tar.gz
chown -R www-data:www-data wordpress

cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
sed -i "s/database_name_here/wordpress/g" /var/www/html/wordpress/wp-config.php
sed -i "s/username_here/admin/g" /var/www/html/wordpress/wp-config.php
sed -i "s/password_here/password1234/g" /var/www/html/wordpress/wp-config.php
sed -i "s/localhost/${aws_rds_cluster.main.endpoint}/g" /var/www/html/wordpress/wp-config.php

systemctl restart apache2
EOF
  )
  depends_on = [module.network.aws_nat_gateway]
}


resource "aws_autoscaling_group" "main" {
  name                      = "bjgomes-terraform-test"
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  vpc_zone_identifier       = [for subnet in module.network.private_subnets : subnet.id]
  target_group_arns         = [aws_lb_target_group.main.arn]


  launch_template {
    id      = aws_launch_template.main.id
    version = aws_launch_template.main.latest_version
  }
  depends_on = [module.network.aws_nat_gateway, aws_rds_cluster_instance.main]

}
