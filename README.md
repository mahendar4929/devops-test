# Instructions

1. Create Jenkins and Windows servers in aws using terraform

```bash
$ cd terraform
$ terraform init -var "winpassword=<password>"
$ terraform apply -var "winpassword=<password>"
```

2. Ubuntu server will be created with jenkins installed.
3. Windows server will be created with username 'Administrator' and password passed while running terraform.
4. `terraform output` will provide the ssh key to ssh into the jnekins instance.
1. SSH into the jenkins instance.
2. Get admin password from /var/lib/jenkins/secrets/initialAdminPassword.
3. Access jenkins with IP address (can be obtained from terraform output) of jenkins instance at port 80
4. Login with admin password
5. Install suggested plugins and set up new user.
6. Create a new jenkins pipeline job and select pipeline from scm and provide github url as https://github.com/mahendar4929/devops-test.git.
7. Run and test the job with correct parameters and confirm playbook is executed properly.
