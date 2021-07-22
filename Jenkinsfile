pipeline {
  agent any
    stages {
        stage('Setup parameters') {
            steps {
                script {
                    properties([
                        parameters([
                            string(
                                defaultValue: 'Administrator',
                                name: 'username',
                                trim: true
                            ),
                            string(
                                defaultValue: 'default',
                                name: 'password',
                                trim: true
                            ),
                            string(
                                defaultValue: '192.168.0.1',
                                name: 'ipaddress',
                                trim: true
                            )
                        ])
                    ])
                }
            }
        }
        stage('Create Inventory') {
            steps {
                sh """
                #!/bin/bash
                cat >inv <<EOF
                [winhost]
                ${ipaddress}
                """
            }
        }
        stage ('Windows Update') {
            steps {
                  sh '''
                  ansible-playbook -i inv ansible/playbook.yaml --extra-vars "ansible_user=${username} ansible_password=${password} ansible_port=5986 ansible_connection=winrm ansible_winrm_server_cert_validation=ignore"
                  '''
            }
        }

    }
 }
