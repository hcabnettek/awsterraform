
output "server_public_ip" {
 value = aws_eip.one.public_ip
}

output "server_private_ip" {
  value = aws_instance.bookstore_web_server.private_ip

}

output "server_id" {
  value = aws_instance.bookstore_web_server.id
}
