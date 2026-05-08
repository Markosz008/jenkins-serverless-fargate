pipeline {
    agent any
    
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        DB_PASS               = credentials('DB_PASS') // Itt tároljuk a titkos jelszót
        DOCKER_USER           = 'markosz008'
        DOCKER_PASS           = credentials('DOCKER_PASS')
        IMAGE_NAME            = "markosz008/flask-app:latest"
        REGION                = "eu-central-1"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    // Átadjuk a jelszót változóként!
                    sh "terraform apply -var='db_password=${DB_PASS}' --auto-approve"
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                // Fontos az amd64 platform a Fargate miatt!
                sh "docker build --platform linux/amd64 -t ${IMAGE_NAME} ."
                sh "docker push ${IMAGE_NAME}"
            }
        }

        stage('Deploy to ECS') {
            steps {
                // Megmondjuk az ECS-nek, hogy jött új image, indítson új Taskot (Blue-Green alap)
                sh "aws ecs update-service --cluster serverless-cluster --service flask-service --force-new-deployment --region ${REGION}"
            }
        }
    }
}