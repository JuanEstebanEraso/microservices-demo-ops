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
                // Verificamos que el docker-compose.yml no tenga errores de indentación
                sh 'docker-compose config --quiet'
                echo "Configuración de Docker válida."
            }
        }

        stage('Deploy to VM') {
            steps {
                // Usamos la llave privada guardada en Jenkins para entrar a la VM
                sshagent(['vm-app-ssh-key']) {
                    sh """
                        echo "Ejecutando script de despliegue en la VM..."
                        
                        # Conexión SSH: ejecutamos el script que ya vive en tu VM.
                        # Pasamos 'latest' como tag por defecto para que el script actualice el .env
                        ssh -o StrictHostKeyChecking=no ${VM_APP_USER}@${VM_APP_HOST} \
                            "bash /home/azureuser/microservices-demo-ops/scripts/deploy.sh latest ${ACR_LOGIN_SERVER} ${ACR_NAME}"
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
