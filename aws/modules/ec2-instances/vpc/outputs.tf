output "public_vpc" {
  value = aws_vpc.public
}

output "public_subnet" {
  value = aws_subnet.public
}

output "public_sg" {
  value = aws_security_group.public
}

output "private_vpc" {
  value = aws_vpc.private
}

output "private_subnet" {
  value = aws_subnet.private
}

output "private_sg" {
  value = aws_security_group.private
}