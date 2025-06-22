resource "aws_instance" "face_app" {
  ami           = "ami-0b05d988257befbbe"
  instance_type = "t2.medium"
  key_name      = "face-key"
  subnet_id     = aws_subnet.face_subnet.id
  security_groups = [aws_security_group.ec2_sg.id]

  provisioner "file" {
    source      = "${path.module}/app"
    destination = "/home/ubuntu/app"
  }

  provisioner "file" {
    source      = "${path.module}/setup_face_app.sh"
    destination = "/home/ubuntu/setup_face_app.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/setup_face_app.sh",
      "bash /home/ubuntu/setup_face_app.sh"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/face-key.pem")
    host        = self.public_ip
  }

  tags = {
    Name = "FaceAppInstance"
  }
}