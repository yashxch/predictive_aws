pipeline {
    agent any

    stages {
        stage('Build Docker') {
            steps {
                sh 'docker build -t predictive-app .'
            }
        }

        stage('Run Container') {
            steps {
                sh 'docker run -d -p 8000:8000 predictive-app'
            }
        }
    }
}