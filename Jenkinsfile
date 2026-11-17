pipeline {
    agent any

    parameters {
        choice(
            name: 'DEPLOY_NAMESPACE',
            choices: ['ngrp', 'default'],
            description: 'Select Kubernetes Namespace'
        )
        string(
            name: 'BRANCH',
            defaultValue: 'master',
            description: 'Enter source code branch'
        )
    }

    environment {
        SOURCE_DIR          = "."
        DOCKERFILE_PATH     = "Dockerfile"
        GIT_REPO            = "https://github.com/aditya-vikram90/frontend-minikube-pipeline.git"

        DOCKER_REPO         = "192.168.58.2:30500"
        DOCKER_IMAGE_NAME   = "frontend-app"

        DEPLOYMENT_NAME     = "frontend-app"
        CONTAINER_NAME      = "frontend"

        NPM_REGISTRY_URL    = "http://192.168.58.2:30081/repository/npmjs-proxy/"
        KUBECONFIG          = "/home/neo/Documents/minikube-setup/jenkins-kubeconfig"
    }

    stages {
        stage('Checkout Source Branch') {
            steps {
                script {
                    echo '--- Checking out Source Branch ---'
                    // Agar Pipeline from SCM use ho raha hai:
                    if (env.SCM_URL || env.GIT_URL) {
                        checkout scm
                    } else {
                        // Agar direct pipeline script run ho rahi hai, to local directory ya git se clone karega
                        dir("${SOURCE_DIR}") {
                            sh 'echo "Using workspace repository code"'
                        }
                    }
                }
            }
        }

        stage('Generate Tag') {
            steps {
                script {
                    dir("${SOURCE_DIR}") {
                        def commitId = sh(script: 'git rev-parse --short HEAD || echo "local"', returnStdout: true).trim()
                        def datetimeIST = sh(script: "TZ=Asia/Kolkata date +%d%m%Y_%H%M", returnStdout: true).trim()
                        env.DOCKER_IMAGE_TAG = "${commitId}_${datetimeIST}"
                        echo "Docker Image Tag Generated: ${env.DOCKER_IMAGE_TAG}"
                    }
                }
            }
        }

        stage('Podman Build & Push') {
            steps {
                script {
                    echo '--- Building and Pushing Image using Nexus NPM Proxy ---'
                    dir("${SOURCE_DIR}") {
                        sh """
                            podman build \
                                -f ${DOCKERFILE_PATH} \
                                --build-arg NPM_REGISTRY=${NPM_REGISTRY_URL} \
                                -t ${DOCKER_REPO}/${DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} \
                                -t ${DOCKER_REPO}/${DOCKER_IMAGE_NAME}:latest .

                            podman push --tls-verify=false ${DOCKER_REPO}/${DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}
                            podman push --tls-verify=false ${DOCKER_REPO}/${DOCKER_IMAGE_NAME}:latest
                        """
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    kubectl --kubeconfig=${KUBECONFIG} set image deployment/${DEPLOYMENT_NAME} \
                      ${CONTAINER_NAME}=${DOCKER_REPO}/${DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} \
                      -n ${params.DEPLOY_NAMESPACE}
                """
            }
        }

        stage('Rollout Status') {
            steps {
                sh """
                    kubectl --kubeconfig=${KUBECONFIG} rollout status deployment/${DEPLOYMENT_NAME} \
                      -n ${params.DEPLOY_NAMESPACE} --timeout=300s
                """
            }
        }
    }

    post {
        always {
            echo '--- Cleanup: local image remove ---'
            sh """
                if [ -n "${env.DOCKER_IMAGE_TAG}" ]; then
                    podman rmi -f ${DOCKER_REPO}/${DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} || true
                fi
            """
        }
        success {
            echo "✅ Deployment Successful 🚀"
            echo "Namespace : ${params.DEPLOY_NAMESPACE}"
            echo "Image     : ${DOCKER_REPO}/${DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
            echo "App URL   : http://192.168.58.2:30080"
        }
        failure {
            echo "❌ Deployment Failed"
        }
    }
}
