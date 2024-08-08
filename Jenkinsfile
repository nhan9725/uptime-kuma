pipeline {
    agent {
        kubernetes {
            yamlFile 'k8s/KubernetesPod.yaml'
        }
    }

    environment {
        SONARCLOUD = 'test-sonar' // Ensure this is the correct credentials ID
        SONAR_ORG = 'test-3107' // Your Sonar organization
        SONAR_PROJECT_KEY = 'test-3107' // Your Sonar project key
        CACHE_KEY = '' // To store the checksum of package.json
        CACHE_DIR = '/home/jenkins/agent/workspace/cache-fe' // Cache directory on the Jenkins agent
    }

    stages {
        stage ('Check for existence of index.html') {
            steps {
                container('nextjs') {
                    script {
                        if (fileExists('/home/jenkins/agent/workspace/cache-fe/dependencies-9e80c5051af62a08fc2b6cc2b5f90e02.tar')) {
                            echo "File dependencies-9e80c5051af62a08fc2b6cc2b5f90e02.tar found!"
                        } else {
                            echo "No file found"
                        }
                    }
                }
            }
        }

        stage('Cache Calculate Checksum if Installed Dependencies') {
            steps {
                container('nextjs') {
                    script {
                        // Calculate the checksum for package.json
                        env.CACHE_KEY = sh(
                            script: 'md5sum package.json | awk \'{ print $1 }\'',
                            returnStdout: true
                        ).trim()
                        echo "Calculated Checksum: ${env.CACHE_KEY}"

                        // Define the path to the cache file
                        def cachePath = "${env.CACHE_DIR}/dependencies-${env.CACHE_KEY}.tar"

                        // Check if the cache file exists
                        def cacheHit = fileExists(cachePath)
                        if (cacheHit) {
                            echo "Cache hit, extracting dependencies..."
                            sh "tar -xf ${cachePath}"
                        } else {
                            echo "Cache miss, running yarn install..."
                            sh 'yarn install'
                            sh "mkdir -p ${env.CACHE_DIR} && tar -cf ${cachePath} node_modules"
                        }
                    }
                }
            }
        }

        stage('Unit Test') {
            steps {
                container('nextjs') {
                    script {
                        if (fileExists('VERSION')) {
                            def version = readFile('VERSION').trim() // Ensure VERSION file is read correctly
                            echo "Testing version ${version}..."
                        } else {
                            echo "VERSION file not found, skipping version display."
                        }

                        // create logs
                        try {
                            // Run tests with coverage
                            sh 'yarn test --coverage'

                            // Ensure coverage report exists
                            sh 'ls -l coverage/jest'

                        } catch (Exception e) {
                            echo "Error during testing: ${e.message}"
                            currentBuild.result = 'FAILURE'
                            throw e
                        }
                    }
                }
            }
            post {
                always {
                    container('nextjs') {
                        script {
                            if (fileExists('coverage/jest/cobertura-coverage.xml')) {
                                echo "Cobertura coverage report found."
                                step([$class: 'CoberturaPublisher', coberturaReportFile: 'coverage/jest/cobertura-coverage.xml'])
                            } else {
                                echo "Cobertura coverage report not found."
                                sh 'ls -l coverage/jest'
                            }
                        }
                    }
                }
            }
        }

        stage('Unit Install and Build') {
            steps {
                container('nextjs') {
                    script {
                        // Install dependencies using Yarn
                        sh 'yarn install'
                        sh 'yarn build'
                        sh 'yarn cache dir'
                    }
                }
            }
        }

        stage('Wait for Input') {
            steps {
                container('nextjs') {
                    script {
                        input message: 'Proceed to SonarQube analysis?', ok: 'Yes'
                    }
                }
            }
        }

        stage('SonarQube analysis') {
            steps {
                container('nextjs') {
                    script {
                        def scannerHome = tool 'sonar-test' // must match the name of an actual scanner installation directory on your Jenkins build agent
                        withSonarQubeEnv('SonarCloud') { // If you have configured more than one global server connection, you can specify its name as configured in Jenkins
                            sh """
                                ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.organization=${SONAR_ORG} \
                                -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                -Dsonar.sources=. \
                                -Dsonar.host.url=https://sonarcloud.io \
                                -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info 
                            """
                        }
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                container('nextjs') {
                    script {
                        def version = readFile('VERSION').trim() // Ensure VERSION file is read correctly
                        echo "Deploying version ${version}..."
                    }
                }
            }
        }

        stage('Tag Version') {
            steps {
                container('nextjs') {
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
    }

    post {
        always {
            junit 'reports/**/*.xml' // Adjust to your test report location
            archiveArtifacts artifacts: '**/coverage/**', allowEmptyArchive: true
            script {
                // Wait for SonarQube analysis to be completed
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
}
