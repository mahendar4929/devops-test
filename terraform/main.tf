data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data "aws_ami" "latest-windows-server-2016" {
  most_recent = true
  owners      = ["801119661308"] # Canonical

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  depends_on = [tls_private_key.private_key]
  key_name   = var.key_name
  public_key = tls_private_key.private_key.public_key_openssh
}

variable "key_name" {
  default = "ec2-instance-key"
}

resource "aws_security_group" "web_traffic" {
  name        = "Allow web traffic"
  description = "Allow ssh and standard http/https ports inbound and everything outbound"

  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Terraform" = "true"
  }
}

resource "aws_instance" "jenkins" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.small"
  security_groups = [aws_security_group.web_traffic.name]
  key_name        = var.key_name

  provisioner "remote-exec" {
    inline = [
      "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
      "echo deb http://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list",
      "sudo apt update -qq",
      "sudo apt install -y default-jre",
      "sudo apt install -y jenkins",
      "sudo systemctl start jenkins",
      "sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080",
      "sudo sh -c \"iptables-save > /etc/iptables.rules\"",
      "echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections",
      "echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections",
      "sudo apt-get -y install iptables-persistent",
      "sudo ufw allow 8080",
      "sudo apt install -y apt-transport-https ca-certificates curl software-properties-common",
      "sudo apt update",
      "sudo apt install -y ansible"
    ]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.private_key.private_key_pem
  }

  tags = {
    "Name"      = "Jenkins_Server"
    "Terraform" = "true"
  }
}

resource "aws_instance" "win_instance" {
  ami             = data.aws_ami.latest-windows-server-2016.id
  instance_type   = "t2.small"
  security_groups = [aws_security_group.web_traffic.name]
  key_name        = var.key_name
  user_data       = <<EOF
  <powershell>
  $admin = [adsi]("WinNT://./Administrator, user")
  $admin.PSBase.Invoke("SetPassword", "${var.winpassword}")
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $Url = 'https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1'
  $PSFile = 'C:\ConfigureRemotingForAnsible.ps1'
  Invoke-WebRequest -Uri $Url -OutFile $PSFile
  C:\ConfigureRemotingForAnsible.ps1
  </powershell>
  EOF

  provisioner "remote-exec" {
    inline = ["echo booted"]

    connection {
      type     = "winrm"
      user     = "Administrator"
      password = var.winpassword
      host     = aws_instance.win_instance.public_ip
      port     = 5986
      insecure = true
      https    = true
      timeout  = "10m"
    }
  }

}
