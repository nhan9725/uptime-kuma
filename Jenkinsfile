pipeline {
    agent any
  
    environment {
    SONARCLOUD = 'Sonarcloud'
    }
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Git Checkout SCM') {
            steps {
              checkout scm
            }
        }

        stage('Compile and Run Sonar Analysis') {
            steps {
                script {
                    withSonarQubeEnv(credentialsId: SONARCLOUD, installationName: 'Sonarcloud') {
                        try {
                            if (fileExists('package.json')) {
                                sh "${sonarscanner} -Dsonar.organization=test-sonar -Dsonar.projectKey=test-3107 -Dsonar.sources=. -Dsonar.host.url=https://sonarcloud.io"
                            } 
                            else {
                                currentBuild.result = 'FAILURE'
                                pipelineError = true
                                error("Unsupported application type: No compatible build steps available.")
                            }
                        } catch (Exception e) {
                            currentBuild.result = 'FAILURE'
                            pipelineError = true
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
        
        stage('Test') {
            steps {
                script {
                    def version = readFile('VERSION').trim() // Ensure VERSION file is read correctly
                    echo "Testing version ${version}..."
                    // Run tests with coverage
                    sh 'yarn test --coverage'
                }
            }
        }

        stage('Code Coverage') {
            steps {
                script {
                    // Record and publish code coverage reports using JaCoCo
                    recordCoverage tools: [[parser: 'JACOCO']],
                        id: 'jacoco', name: 'JaCoCo Coverage',
                        sourceCodeRetention: 'EVERY_BUILD',
                        qualityGates: [
                            [threshold: 60.0, metric: 'LINE', baseline: 'PROJECT', unstable: true],
                            [threshold: 60.0, metric: 'BRANCH', baseline: 'PROJECT', unstable: true]
                        ]
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
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
    post {
        always {
            junit 'reports/**/*.xml' // Adjust to your test report location
            archiveArtifacts artifacts: '**/coverage/**', allowEmptyArchive: true
        }
    }
}
