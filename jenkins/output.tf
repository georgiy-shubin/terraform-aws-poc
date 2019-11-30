output "ssh_connection" {
  value = format("ssh -i \"%s\" ubuntu@%s", aws_instance.jenkins-instnace.key_name, aws_instance.jenkins-instnace.public_dns)
  # value = format("ssh -i \"%s\" ubuntu@%s", aws_instance.jenkins-instnace.key_name, aws_route53_record.jenkins.name)
}

output "jenkins_address" {
  value = format("http://%s:8080", aws_route53_record.jenkins.name)
}