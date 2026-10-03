// CI/CD pipeline for the webapp (doc pages 69-71, updated):
//  - the doc's version used `minikube ssh` / `scp`, which cannot work on a kubeadm cluster
//  - the multi-stage Dockerfile compiles Angular, so no Node.js is needed on the Jenkins machine
//  - images go to Docker Hub user motez00 via the 'dockerhub' Jenkins credential
def commit_id

pipeline {
    agent any

    environment {
        IMAGE = 'motez00/fleetman-webapp'
    }

    stages {
        stage('Preparation') {
            steps {
                checkout scm
                sh 'git rev-parse --short HEAD > .git/commit-id'
                script {
                    commit_id = readFile('.git/commit-id').trim()
                }
            }
        }

        stage('Image Build') {
            steps {
                echo "Building ${IMAGE}:${commit_id} (npm ci + ng build run inside Docker)"
                sh "docker build -t ${IMAGE}:${commit_id} -t ${IMAGE}:latest ."
            }
        }

        stage('Image Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub',
                                                  usernameVariable: 'DOCKER_USER',
                                                  passwordVariable: 'DOCKER_TOKEN')]) {
                    // single quotes: the shell expands the secret, Groovy never sees it
                    sh 'echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USER" --password-stdin'
                    sh "docker push ${IMAGE}:${commit_id}"
                    sh "docker push ${IMAGE}:latest"
                }
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying to Kubernetes'
                sh "sed -i 's|${IMAGE}:.*|${IMAGE}:${commit_id}|' k8s/deployment.yaml"
                sh 'kubectl apply -f k8s/'
                sh 'kubectl rollout status deployment/webapp --timeout=180s'
                sh 'kubectl get pods -l app=webapp -o wide'
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
    }
}
