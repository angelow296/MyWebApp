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

variable "source_ami" {
  type    = string
  default = "ami-0e9a81e2d672e1017"  # Replace with the AMI ID from the prerequisite build
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "windows-ami" {
  ami_name      = "packer-windows-application-${local.timestamp}"
  communicator  = "winrm"
  instance_type = "t2.micro"
  region        = "${var.region}"
  source_ami    = "${var.source_ami}"

  winrm_username = "Administrator"
  winrm_password = "SuperS3cr3t!!!!"
  winrm_insecure = true
  winrm_use_ssl  = false
  winrm_timeout  = "10m"

  ami_block_device_mappings {
    device_name           = "/dev/sda1"
    delete_on_termination = true
  }

  user_data_file = "bootstrap_win.txt"
}

build {
  name    = "windows-application"
  sources = ["source.amazon-ebs.windows-ami"]

  provisioner "powershell" {
    inline = [
      "winrm quickconfig -quiet",
      "Set-Item WSMan:\\localhost\\Service\\AllowUnencrypted -Value true",
      "Set-Item WSMan:\\localhost\\Service\\Auth\\Basic -Value true",
      "Enable-WSManCredSSP -Role Server",
      "Restart-Service WinRM"
    ]
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing application...'",
      "New-Item -Path 'C:\\app' -ItemType Directory",
      "Invoke-WebRequest -Uri 'https://example.com/myapp.zip' -OutFile 'C:\\app\\myapp.zip'",
      "Expand-Archive -Path 'C:\\app\\myapp.zip' -DestinationPath 'C:\\app'"
    ]
  }
}
