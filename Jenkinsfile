pipeline {
    agent any

    environment {
        DOCKER_HUB_REPO = 'trong101/weather-app'
        GIT_REPO_NAME = 'WeatherApp'
        GIT_USER_NAME = 'hieutrong285'
        DEPLOY_JOB_NAME = 'eks-deployment'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'CI/CD', 
                    credentialsId: 'github', 
                    url: 'https://github.com/hieutrong285/WeatherApp.git'
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry([credentialsId: 'docker', url: 'https://index.docker.io/v1/']) {
                        sh "docker build -t ${DOCKER_HUB_REPO} ."
                        sh "docker tag ${DOCKER_HUB_REPO} ${DOCKER_HUB_REPO}:${BUILD_NUMBER}"
                        sh "docker push ${DOCKER_HUB_REPO}:${BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Update Deployment File') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'github', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASSWORD')]) {
                        def NEW_IMAGE_NAME = "${DOCKER_HUB_REPO}:${BUILD_NUMBER}"

                        sh "git checkout CI/CD"
                        sh "git pull origin CI/CD"
                        sh "sed -i 's|image: .*|image: ${NEW_IMAGE_NAME}|' ./manifest-files/deployment.yaml"

                        if (sh(returnStatus: true, script: "git diff --quiet --exit-code ./k8s-manifest/deployment.yaml") != 0) {
                            sh 'git config --global user.email "jenkins@example.com"'
                            sh 'git config --global user.name "Jenkins CI"'
                            sh 'git add ./manifest-files/deployment.yaml'
                            sh "git commit -m 'Update deployment image to ${NEW_IMAGE_NAME}'"
                            
                            sh """
                                git push https://${GIT_USER}:${GIT_PASSWORD}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME}.git HEAD:CI/CD
                            """

                            // Trigger deployment pipeline
                            build job: "${DEPLOY_JOB_NAME}", 
                                  wait: false, 
                                  parameters: [
                                      string(name: 'DOCKER_TAG', value: "${BUILD_NUMBER}"),
                                      string(name: 'GIT_BRANCH', value: 'jenkins'),
                                      string(name: 'DEPLOYMENT_PATH', value: './manifest-files/deployment.yaml')
                                  ]
                        } else {
                            echo "No changes to deployment.yaml, skipping commit and push."
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Build and update pipeline completed successfully!'
        }
        failure {
            echo 'Build and update pipeline failed!'
        }
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
    }
}
