pipeline {
    agent any

    environment {
        // Configuración de Azure corregida según tus recursos
        ACR_NAME         = 'acrapp1'
        ACR_LOGIN_SERVER = "${ACR_NAME}.azurecr.io"
        
        // Estos IDs deben coincidir con los que creaste en Jenkins (Manage Jenkins -> Credentials)
        ACR_CREDENTIALS  = credentials('acr-credentials') 
        VM_APP_HOST      = credentials('vm-app-host')      
        VM_APP_USER      = 'azureuser'
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '5'))
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout Ops Repo') {
            steps {
                // Descarga los archivos de infraestructura del repo de Ops
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        stage('Validate Config') {
            steps {
                sshagent(['vm-app-ssh-key']) {
                    sh 'ssh -o StrictHostKeyChecking=no ${VM_APP_USER}@${VM_APP_HOST} "docker-compose -f /home/azureuser/microservices-demo-ops/docker-compose.yml config --quiet"'
                    echo " Configuración de Docker validada remotamente."
                }
            }
        }

        stage('Deploy to VM') {
            steps {
                sshagent(['vm-app-ssh-key']) {
                    sh """
                        # Jenkins se conecta por SSH y le dice a la VM: 
                        # "Oye VM, actualiza tu carpeta con lo último de GitHub y reinicia Nginx"
                        ssh -o StrictHostKeyChecking=no ${VM_APP_USER}@${VM_APP_HOST} "
                            cd /home/azureuser/microservices-demo-ops && \
                            git pull origin main && \
                            bash scripts/deploy.sh latest ${ACR_LOGIN_SERVER} ${ACR_NAME} && \
                            docker-compose up -d --force-recreate nginx
                        "
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                echo "Verificando estado del Gateway..."
                // Damos un tiempo de gracia para que Nginx y los servicios suban
                sleep 15
                
                // Probamos el endpoint que configuraste en tu nginx.conf
                sh """
                    curl --fail --silent --max-time 10 http://${VM_APP_HOST}/health \
                        && echo "Nginx Gateway: Online" \
                        || (echo "Error: El Gateway no responde" && exit 1)
                """
            }
        }
    }

    post {
        success {
            echo "¡Infraestructura actualizada con éxito!"
        }
        failure {
            echo "El despliegue falló. Revisa los logs de Jenkins y el estado de la VM."
        }
        always {
            // Limpieza del workspace en el servidor de Jenkins
            cleanWs()
        }
    }
}
