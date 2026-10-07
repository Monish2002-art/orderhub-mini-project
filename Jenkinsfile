pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timeout(time: 1, unit: 'HOURS')
        ansiColor('xterm')
    }

    environment {
        REGISTRY = "myregistry.azurecr.io/orderhub"
        // Immutable Tagging Strategy: buildNumber-shortGitCommit
        IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : 'local'}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Unit Tests') {
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install -r requirements.txt
                    pytest tests/
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build --build-arg BUILD_NUMBER=${env.BUILD_NUMBER} --build-arg GIT_COMMIT=${env.GIT_COMMIT} -t ${REGISTRY}:${IMAGE_TAG} ."
            }
        }

        stage('Test Docker Image Locally') {
            steps {
                sh """
                    docker run -d --name orderhub-test -p 8080:8080 \
                      -e BUILD_NUMBER=${env.BUILD_NUMBER} \
                      -e GIT_COMMIT=${env.GIT_COMMIT} \
                      ${REGISTRY}:${IMAGE_TAG}
                """
                sh "sleep 3"
                sh "curl -f http://localhost:8080/health"
                sh "curl -f http://localhost:8080/version"
                sh "docker rm -f orderhub-test"
            }
        }

        stage('Push to Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-registry-creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
                    sh "echo ${REG_PASS} | docker login ${REGISTRY} -u ${REG_USER} --password-stdin"
                    sh "docker push ${REGISTRY}:${IMAGE_TAG}"
                }
            }
        }

        stage('Approval') {
            steps {
                input message: "Promote and deploy immutable build version ${IMAGE_TAG} to production?",
                      ok: "Deploy"
            }
        }

        stage('Deploy to Production VM') {
            steps {
                sshagent(['prod-server-ssh-key']) {
                    // Transfer and execute deployment script remotely
                    sh "scp deploy.sh user@prod-server:/tmp/deploy.sh"
                    sh "ssh user@prod-server 'bash /tmp/deploy.sh ${REGISTRY} ${IMAGE_TAG}'"
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "Pipeline completed successfully for version ${IMAGE_TAG}!"
        }
        failure {
            echo "Pipeline failed. Check console logs for details."
        }
    }
}