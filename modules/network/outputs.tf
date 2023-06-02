output "aws_public_subnet" {
  value = aws_subnet.public
}

output "aws_private_subnet" {
  value = aws_subnet.private
}

output "aws_security_group_id" {
  value = aws_security_group.main.id
}