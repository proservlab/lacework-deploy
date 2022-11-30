output "vpc" {
  value = aws_vpc.public
}

output "subnet" {
  value = aws_subnet.public
}

output "sg" {
  value = aws_security_group.public
}