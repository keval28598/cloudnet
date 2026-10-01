output "web_server_public_ip" {
  description = "Public IP address of the CloudNet web server"
  value       = aws_instance.web_server.public_ip
}

output "web_server_url" {
  description = "Direct HTTP URL to access the web server"
  value       = "http://${aws_instance.web_server.public_ip}"
}