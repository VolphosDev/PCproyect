output "instance_public_ip" {
  description = "IP pública de la instancia EC2"
  value       = aws_instance.face_app.public_ip
}

output "app_url" {
  description = "URL de acceso a la app Flask"
  value       = "http://${aws_instance.face_app.public_ip}:5000"
}

output "ssh_command" {
  description = "Comando para conectarte vía SSH"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.face_app.public_ip}"
}