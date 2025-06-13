variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "CIDR para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR para la Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Zona de disponibilidad"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Nombre de la clave SSH"
  type        = string
  default     = "face-key"
}

variable "ami_id" {
  description = "ID de la imagen AMI Ubuntu"
  type        = string
  default     = "ami-0b05d988257befbbe"
}

variable "project_name" {
  description = "Nombre del proyecto para etiquetas"
  type        = string
  default     = "face-recognition-app"
}

variable "env" {
  description = "Entorno (dev, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "allowed_ssh_cidr" {
  description = "CIDR para acceso SSH (restringe por IP si puedes)"
  type        = string
  default     = "0.0.0.0/0"
}
