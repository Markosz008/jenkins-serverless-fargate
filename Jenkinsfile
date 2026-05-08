pipeline {
    agent any

    // 1. Paraméter beállítása a Jenkins felülethez
    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Válaszd ki: apply (építés/frissítés) vagy destroy (teljes törlés)')
    }
    
    // A TE pontos környezeti változóid
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        DB_PASS               = credentials('DB_PASSWORD') // Itt tároljuk a titkos jelszót
        DOCKER_USER           = 'markosz008'
        DOCKER_PASS           = credentials('fargate-docker-token')
        IMAGE_NAME            = "markosz008/flask-app:latest"
        REGION                = "eu-central-1"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // Ketté szedtem az Initet és az Akciót, hogy tisztább legyen
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Action') {
            steps {
                dir('terraform') {
                    script {
                        // Itt döntjük el a paraméter alapján, mit csináljon
                        if (params.ACTION == 'apply') {
                            echo "Indul az építés (Apply)..."
                            sh "terraform apply -var='db_password=${DB_PASS}' --auto-approve"
                        } else if (params.ACTION == 'destroy') {
                            echo "Indul a takarítás (Destroy)..."
                            sh "terraform destroy -var='db_password=${DB_PASS}' --auto-approve"
                        }
                    }
                }
            }
        }

        stage('Docker Build & Push') {
            // Ez a stage CSAK akkor fut le, ha az ACTION = apply
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                // Fontos az amd64 platform a Fargate miatt!
                sh "docker build --platform linux/amd64 -t ${IMAGE_NAME} ."
                sh "docker push ${IMAGE_NAME}"
            }
        }

        stage('Deploy to ECS') {
            // Ez a stage is CSAK akkor fut le, ha az ACTION = apply
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                // Megmondjuk az ECS-nek, hogy jött új image, indítson új Taskot (Blue-Green alap)
                sh "aws ecs update-service --cluster serverless-cluster --service flask-service --force-new-deployment --region ${REGION}"
            }
        }
    }
}