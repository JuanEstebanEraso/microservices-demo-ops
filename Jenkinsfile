pipeline {
    agent any

    environment {
        ACR_NAME         = 'NOMBRE-DE-TU-ACR'
        ACR_LOGIN_SERVER = "${ACR_NAME}.azurecr.io"
        ACR_CREDENTIALS  = credentials('acr-credentials')
        VM_APP_HOST      = credentials('vm-app-host')
        VM_APP_USER      = 'azureuser'
    }

    options {
        timeout(time: 20, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        stage('Validate docker-compose') {
            steps {
                sh '''
                    docker-compose config --quiet
                    echo "docker-compose.yml valido"
                '''
            }
        }

        stage('Deploy') {
            steps {
                sshagent(['vm-app-ssh-key']) {
                    sh '''
                        chmod +x scripts/deploy.sh
                        ssh -o StrictHostKeyChecking=no \
                            ${VM_APP_USER}@${VM_APP_HOST} \
                            "bash /home/azureuser/microservices-demo-ops/scripts/deploy.sh \
                                latest \
                                ${ACR_LOGIN_SERVER} \
                                ${ACR_NAME}"
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    sleep 20
                    curl --fail --silent --max-time 10 \
                        http://${VM_APP_HOST}/health \
                        && echo "Gateway OK" \
                        || echo "Gateway NO RESPONDE"
                '''
            }
        }
    }

    post {
        success {
            echo "Pipeline de infraestructura completado exitosamente"
        }
        failure {
            echo "Pipeline de infraestructura fallido"
        }
    }
}
