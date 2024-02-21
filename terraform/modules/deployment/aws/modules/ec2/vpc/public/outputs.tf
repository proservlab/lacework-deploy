output "vpc" {
  value = aws_vpc.public
}

output "subnet" {
  value = aws_subnet.public
}

output "sg" {
  value = aws_security_group.public
}

output "igw" {
  value = aws_internet_gateway.public
}

output "route_table" {
  value = aws_route_table.public
}