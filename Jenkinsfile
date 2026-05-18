pipeline {
    agent any

    stages {
        stage('Clean Docker Environment') {
            steps {
                echo 'Cleaning old Docker containers and database files...'
                sh 'docker rm -f df-api doubtfire-dev-db || true'
                sh 'docker compose down --remove-orphans || true'
                sh 'rm -rf ../data/database ../data/tmp ../data/student-work || true'
            }
        }

        stage('Build') {
            steps {
                echo 'Building Docker image for Doubtfire API...'
                sh 'docker compose build'
            }
        }

        stage('Prepare Database') {
            steps {
                echo 'Starting database and loading schema...'
                sh 'docker compose up -d dev-db'
                sh 'sleep 30'
                sh 'docker compose run --rm --entrypoint "" df-api bundle exec rails db:schema:load'
            }
        }

        stage('Test') {
            steps {
                echo 'Running pipeline CRUD test...'
                sh 'docker compose run --rm --entrypoint "" df-api ruby test/pipeline_crud_test.rb'
            }
        }

        stage('Code Quality') {
            steps {
                echo 'Running RuboCop code quality check...'
                sh 'docker compose run --rm --entrypoint "" df-api bundle exec rubocop test/pipeline_crud_test.rb'
            }
        }

        stage('Security') {
            steps {
                echo 'Running Trivy security scan on Docker image...'
                sh '''
                    docker run --rm \
                    -v /var/run/docker.sock:/var/run/docker.sock \
                    aquasec/trivy:latest image \
                    --severity HIGH,CRITICAL \
                    --exit-code 0 \
                    doubtfire-api-df-api:latest | tee trivy-security-report.txt
                '''
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying Doubtfire API container...'
                sh 'docker compose up -d df-api'
                sh 'sleep 20'
                sh 'docker ps'
                sh 'curl -I http://localhost:3000 || true'
            }
        }
    }

    post {
        always {
            echo 'Cleaning up temporary containers...'
            sh 'docker compose ps'
        }
    }
}