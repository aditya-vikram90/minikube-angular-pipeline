pipeline {
  agent any

  environment {
    REGISTRY     = 'localhost:5000'
    IMAGE        = 'angular/my-app'
    NPM_REGISTRY = 'http://192.168.49.2:30081/repository/npmjs-proxy/'
    DIST_DIR     = 'dist/my-app/browser'
  }

  options {
    timestamps()
    disableConcurrentBuilds()
    timeout(time: 30, unit: 'MINUTES')
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Preflight') {
      steps {
        sh 'curl -sf http://localhost:5000/v2/ > /dev/null'
        sh 'curl -sf http://192.168.49.2:30081/service/rest/v1/status > /dev/null'
      }
    }

    stage('Build image') {
      steps {
        script {
          def sha = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          env.TAG = "${BUILD_NUMBER}-${sha}"
        }
        sh '''
          docker build --network host \
            --build-arg NPM_REGISTRY="$NPM_REGISTRY" \
            --build-arg DIST_DIR="$DIST_DIR" \
            -t $REGISTRY/$IMAGE:$TAG \
            -t $REGISTRY/$IMAGE:latest .
        '''
      }
    }

    stage('Push image') {
      steps {
        sh 'docker push $REGISTRY/$IMAGE:$TAG'
        sh 'docker push $REGISTRY/$IMAGE:latest'
      }
    }
  }

  post {
    always  { sh 'docker image prune -f' }
    success { echo "Pushed $REGISTRY/$IMAGE:$TAG" }
  }
}
