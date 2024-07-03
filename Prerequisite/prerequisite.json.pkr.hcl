packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.6"
      source = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "windows-ami" {
  ami_name      = "packer-windows-prerequisite-${local.timestamp}"
  communicator  = "winrm"
  instance_type = "t2.micro"
  region        = "${var.region}"
  source_ami    = "ami-0e9a81e2d672e1017"  # Specified AMI

  winrm_username = "Administrator"
  winrm_password = "SuperS3cr3t!!!!"

  user_data_file = "bootstrap_win.txt"
}

build {
  name    = "windows-prerequisite"
  sources = ["source.amazon-ebs.windows-ami"]

  provisioner "powershell" {
    inline = [
      "Install-WindowsFeature -Name Web-Server",
      "Install-WindowsFeature -Name NET-Framework-45-ASPNET",
      "Install-WindowsFeature -Name Web-Asp-Net45"
    ]
  }
}
