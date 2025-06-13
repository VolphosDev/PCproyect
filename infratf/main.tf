resource "aws_instance" "face_app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = aws_subnet.face_subnet.id
  security_groups = [aws_security_group.ec2_sg.id]

  provisioner "file" {
    source      = "${path.module}/app"
    destination = "/home/ubuntu/app"
  }

    provisioner "remote-exec" {
      inline = [
        "sudo apt-get update -y",
        "sudo apt-get install -y ca-certificates curl gnupg lsb-release",

        "sudo mkdir -p /etc/apt/keyrings",
        "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",

        "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",

        "sudo apt-get update -y",
        "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",

        "sudo systemctl enable docker",
        "sudo systemctl start docker",

        "curl -SL https://github.com/docker/compose/releases/download/v2.24.4/docker-compose-linux-x86_64 -o docker-compose",
        "chmod +x docker-compose",
        "sudo mv docker-compose /usr/local/bin/docker-compose",

        "cd /home/ubuntu/app && sudo docker-compose up -d",

        "sudo fallocate -l 1G /swapfile",
        "sudo chmod 600 /swapfile",
        "sudo mkswap /swapfile",
        "sudo swapon /swapfile",
        "echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab"
      ]
    }


  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("face-key.pem")
    host        = self.public_ip
  }

  tags = {
    Name        = "${var.project_name}-ec2"
    Environment = var.env
  }
}
