pipeline {
  agent {
    node {
      label 'slave'
    }

  }
  stages {
    stage('Hello') {
      steps {
        dir(path: '/root') {
          sh 'echo "hello world"'
        }

      }
    }

  }
}