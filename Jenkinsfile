pipeline {
    agent any

    environment {
        SONARCLOUD = 'SONARCLOUD' // Ensure this is the correct credentials ID
        SONAR_ORG = 'test-sonar' // Your Sonar organization
        SONAR_PROJECT_KEY = 'test-3107' // Your Sonar project key
    }

    stages {

// no need , because define on configure 
//        stage('Git Checkout SCM') {
//            steps {
//                checkout scm
//            }
//    }
        stage('Compile and Run Sonar Analysis') {
            steps {
                script {
                    withSonarQubeEnv('Sonarcloud') { // Use the SonarQube environment configured in Jenkins
                        try {
                            if (fileExists('package.json')) {
                                sh """
                                    ${sonarscanner} \
                                    -Dsonar.organization=${SONAR_ORG} \
                                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                    -Dsonar.sources=. \
                                    -Dsonar.host.url=https://sonarcloud.io \
                                    -Dsonar.login=${SONARCLOUD}
                                """
                            } else {
                                currentBuild.result = 'FAILURE'
                                error("Unsupported application type: No compatible build steps available.")
                            }
                        } catch (Exception e) {
                            currentBuild.result = 'FAILURE'
                            error("Error during Sonar analysis: ${e.message}")
                        }
                    }
                }
            }
        }

        stage('Unit Test') {
            steps {
                script {
                    // Install dependencies using Yarn
                    sh 'yarn install'
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    // Build the application
                    sh 'yarn build'
                }
            }
        }        
                
        stage('Deploy') {
            steps {
                script {
                    def version = readFile('VERSION').trim() // Ensure VERSION file is read correctly
                    echo "Deploying version ${version}..."
                }
            }
        }
        
        stage('Tag Version') {
            steps {
                script {
                    def version = readFile('VERSION').trim() // Ensure VERSION file is read correctly
                    sh "git config user.name 'jenkins'"
                    sh "git config user.email 'jenkins@your-domain.com'"
                    sh "git tag -a ${version} -m 'Release ${version}'"
                    sh "git push origin ${version}"
                }
            }
        }
    }
    
    // post {
    //     always {
    //         junit 'reports/**/*.xml' // Adjust to your test report location
    //         archiveArtifacts artifacts: '**/coverage/**', allowEmptyArchive: true
    //         script {
    //             // Wait for SonarQube analysis to be completed
    //             timeout(time: 1, unit: 'HOURS') {
    //                 waitForQualityGate abortPipeline: true
    //             }
    //         }
    //     }
    // }
}
