output "region" {
    value = var.region
}

output "project_name" {
    value = var.project_name
}

output "vpc_id" {
    value = aws_vpc.my_vpc
}

output "public_1_id" {
    value = aws_subnet.public-1.id
}

output "public_2_id" {
    value = aws_subnet.public-2.id
}

output "app_1_id" {
    value = aws_subnet.app-1.id
}

output "app_2_id" {
    value = aws_subnet.app-2.id
}

output "data_1_id" {
    value = aws_subnet.data-1.id
}

output "data_2_id" {
    value = aws_subnet.data-2.id
}

output "ineternet_gateway" {
    value = aws_internet_gateway.my_igw
}