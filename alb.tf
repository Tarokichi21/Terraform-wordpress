# provider "aws" {
#   profile = "default"
#   region  = "ap-northeast-1"
# }

##########################################################
///ALBの定義
##########################################################
resource "aws_lb" "for_webserver" {
  name               = "webserver-alb"
  internal           = false #falseを指定するとインターネット向け,trueを指定すると内部向け
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb_sg.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_c.id,
  ]
}
##########################################################
///ALBに付与するセキュリティグループの定義
##########################################################

resource "aws_security_group" "alb_sg" {
  name   = "${var.project}-${var.environment}-alb-sg"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name    = "${var.project}-${var.environment}-alb-sg"
    Project = var.project
    Env     = var.environment
  }
}
resource "aws_security_group_rule" "alb_in_http" {
  security_group_id = aws_security_group.alb_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_in_https" {
  security_group_id = aws_security_group.alb_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_out_ec2" {
  security_group_id = aws_security_group.alb_sg.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}
##########################################################
///ALBのリスナーの定義
##########################################################
///リスナールールの定義（HTTP）
# resource "aws_lb_listener" "forward_HTTP" {
#   load_balancer_arn = aws_lb.for_webserver.arn
#   port              = "80"
#   protocol          = "HTTP"
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.for_webserver.arn
#   }
# }

///リスナールールの定義（HTTPS）
resource "aws_lb_listener" "forward_HTTPS" {
  load_balancer_arn = aws_lb.for_webserver.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.tokyo_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.for_webserver.arn
  }
}
##########################################################
///ALBのターゲットグループの定義
##########################################################
resource "aws_lb_target_group" "for_webserver" {
  name     = "${var.project}-${var.environment}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-app-tg"
    Project = var.project
    Env     = var.environment
  }
}

///ターゲットグループをインスタンスに紐づける

resource "aws_lb_target_group_attachment" "for_webserver_a" {
  target_group_arn = aws_lb_target_group.for_webserver.arn
  target_id        = aws_instance.a.id
  port             = 80
}

# resource "aws_lb_target_group_attachment" "for_webserver_c" {
#   target_group_arn = aws_lb_target_group.for_webserver.arn
#   target_id        = aws_instance.c.id
#   port             = 80
# }