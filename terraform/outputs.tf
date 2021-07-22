output "ssh_private_key" {
  value = "${tls_private_key.private_key.private_key_pem}"
}

output "jenkins_ip_address" {
  value = "${aws_instance.jenkins.public_ip}"
}

output "win_instance_ip_address" {
  value = "${aws_instance.win_instance.public_ip}"
}
