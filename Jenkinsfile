pipeline {
    agent any

    stages {
        stage('Clean Docker Environment') {
            steps {
                echo 'Cleaning old Docker containers and database files...'
                sh 'docker rm -f df-api doubtfire-dev-db || true'
                sh 'docker compose down --remove-orphans || true'
                sh 'rm -rf ../data/database ../data/tmp ../data/student-work release || true'
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
                sh 'docker compose run --rm --entrypoint "" df-api bash -lc "DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:schema:load"'
            }
        }

        stage('Test') {
            steps {
                echo 'Running pipeline CRUD and validation tests...'
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
                    doubtfire-api-pipeline-df-api:latest | tee trivy-security-report.txt
                '''
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying Doubtfire API container...'
                sh 'docker compose up -d df-api'
                sh 'sleep 20'
                sh 'docker ps'
                sh 'curl -I http://localhost:3000'
            }
        }

        stage('Release') {
            steps {
                echo 'Creating a release artifact for the successful Docker image...'
                sh '''
                    docker tag doubtfire-api-pipeline-df-api:latest doubtfire-api-pipeline-df-api:release-${BUILD_NUMBER}
                    mkdir -p release
                    docker save doubtfire-api-pipeline-df-api:release-${BUILD_NUMBER} -o release/doubtfire-api-release-${BUILD_NUMBER}.tar
                    ls -lh release/
                '''
                archiveArtifacts artifacts: 'release/*.tar', fingerprint: true
            }
        }

        stage('Monitoring') {
            steps {
                echo 'Running monitoring and health checks on the deployed application...'
                sh '''
                    echo "Checking running containers..."
                    docker ps --filter "name=df-api" --filter "name=doubtfire-dev-db"

                    echo "Checking HTTP response code..."
                    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)

                    echo "Application returned HTTP status: $STATUS_CODE"

                    if [ "$STATUS_CODE" != "200" ]; then
                        echo "Application health check failed"
                        docker logs df-api --tail 50
                        exit 1
                    fi

                    echo "Application health check passed"

                    echo "Recent application logs:"
                    docker logs df-api --tail 30
                '''
            }
        }
    }

    post {
        always {
            echo 'Cleaning up temporary containers...'
            sh 'docker compose ps || true'
        }
    }
}