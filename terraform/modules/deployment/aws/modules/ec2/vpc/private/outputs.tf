
output "vpc" {
  value = aws_vpc.private
}

output "subnet" {
  value = aws_subnet.private
}

output "sg" {
  value = aws_security_group.private
}

output "route_table" {
  value = aws_route_table.private
}