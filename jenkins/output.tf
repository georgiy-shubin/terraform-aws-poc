output "ssh_connection" {
  # value = join("", ["ssh -i \"", aws_instance.gs-instnace.key_name, "\" ubuntu@", aws_instance.gs-instnace.public_dns])
  value = format("ssh -i \"%s\" ubuntu@%s", aws_instance.jenkins-instnace.key_name, aws_instance.jenkins-instnace.public_dns)
}

output "jenkins_address" {
  value = format("http://%s:8080", aws_route53_record.jenkins.name)
}
