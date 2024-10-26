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
        YARN_CACHE_FOLDER = '/usr/local/share/.cache/yarn/v6'
        PROJECT = 'nextjs'
        REGION = 'me-south-1'
        ECR_ID = '082568704422'
        BRANCH_NAME = "${env.BRANCH_NAME ?: 'dev'}" // Default to 'dev' if BRANCH_NAME is not set
        GIT_REPO_URL = 'https://github.com/nhan9725/uptime-kuma.git'
        K8S_MANIFEST_FILE = 'app.yaml'
        IMAGE_TAG = "${JOB_NAME}-${BUILD_NUMBER}"
    }

    stages {
        // stage ('Check for existence of index.html') {
        //     steps {
        //         container('nextjs') {
        //             script {
        //                 if (fileExists('/home/jenkins/agent/workspace/cache-fe/dependencies-9e80c5051af62a08fc2b6cc2b5f90e02.tar')) {
        //                     echo "File dependencies-9e80c5051af62a08fc2b6cc2b5f90e02.tar found!"
        //                 } else {
        //                     echo "No file found"
        //                 }
        //             }
        //         }
        //     }
        // }

        // stage('Cache Calculate Checksum if Installed Dependencies') {
        //     steps {
        //         container('nextjs') {
        //             script {
        //                 // Calculate the checksum for package.json
        //                 env.CACHE_KEY = sh(
        //                     script: 'md5sum package.json | awk \'{ print $1 }\'',
        //                     returnStdout: true
        //                 ).trim()
        //                 echo "Calculated Checksum: ${env.CACHE_KEY}"

        //                 // Define the path to the cache file
        //                 def cachePath = "${env.CACHE_DIR}/dependencies-${env.CACHE_KEY}.tar"

        //                 // Check if the cache file exists
        //                 def cacheHit = fileExists(cachePath)
        //                 if (cacheHit) {
        //                     echo "Cache hit, extracting dependencies..."
        //                     sh "tar -xf ${cachePath}"
        //                 } else {
        //                     echo "Cache miss, running yarn install..."
        //                     sh 'yarn install'
        //                     sh "mkdir -p ${env.CACHE_DIR} && tar -cf ${cachePath} node_modules"
        //                 }
        //             }
        //         }
        //     }
        // }
        stage('Unit Test ') {
            steps {
                container('nextjs') {
                    script {
                        // Install dependencies using Yarn
                        // Set Yarn cache directory to the mounted PVC volume
                        sh 'yarn config set cache-folder $YARN_CACHE_FOLDER'
                        sh 'yarn cache dir'
                        sh 'yarn install --frozen-lockfile --cache-folder $YARN_CACHE_FOLDER'  // mount cache folder on PVC , 1- it will cache dependencies on  /usr/local/share/.cache/yarn/ folder ; 2- try remove cache and run job again
                        sh 'yarn build'
                    }
                }
            }
        }

        stage('Coverage') {
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
                                -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
                                -Dsonar.branch.name=${BRANCH_NAME}
                            """
                        }
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
        stage('Build and push docker image') {
            steps {
                container('docker') {
                    script {
                        withCredentials([aws(credentialsId: 'ecr-test', region: "${REGION}")]) {
                            sh "aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_ID}.dkr.ecr.${REGION}.amazonaws.com"   
                            sh "docker build -t ${PROJECT}:${JOB_NAME}-${BUILD_NUMBER} . -f Dockerfile "
                            sh "docker tag ${PROJECT}:${JOB_NAME}-${BUILD_NUMBER} ${ECR_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}:${JOB_NAME}-${BUILD_NUMBER}"
                            sh "docker push ${ECR_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}:${JOB_NAME}-${BUILD_NUMBER}"
                        }
                    }
                }
            }
        }

        stage('Snyk Scan Vulnerabilities') {
            steps {
                container('docker') {
                    script {
                        // sh 'snyk config set disableSuggestions=true' //remove these messages
                        // sh 'snyk container test ${ECR_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}:${JOB_NAME}-${BUILD_NUMBER}'  // --file=./Dockerfile --exclude-base-image-vulns' //scan both base_image
                        // sh 'snyk container monitor ${ECR_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}:${JOB_NAME}-${BUILD_NUMBER}' // --file=./Dockerfile --exclude-base-image-vulns' //push to snyk cloud 
                        // The default behavior of Snyk is to return a non-zero exit code if any vulnerabilities are found.
                        sh '''
                        set +e
                        snyk container test ${ECR_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}:${JOB_NAME}-${BUILD_NUMBER}
                        snyk container monitor ${ECR_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}:${JOB_NAME}-${BUILD_NUMBER}
                        exitCode=$?
                        set -e
                        echo "Snyk scan completed with exit code ${exitCode}"
                        '''
                    }
                }
            }
        }
        stage ('Approve deployment Application') {
            steps {
                container('nextjs') {
                    script {
                        input message: 'Approve deployment Application', ok: 'Yes'
                    }
                }
            }
        }

        stage('Update GitHub Repository') {
                    steps {
                        container('nextjs') {
                            script {
                            // Clone repository
                            sh """
                            git clone -b ${BRANCH_NAME} ${GIT_REPO_URL}
                            cd k8s
                            """

                            // Update file manifest YAML với tag mới
                            sh """
                            sed -i 's|image: ${ECR_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}:.*|image: ${ECR_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT}:${IMAGE_TAG}|' ${K8S_MANIFEST_FILE}
                            """

                            // Commit và push thay đổi
                            sh """
                            git config user.name "jenkins-bot"
                            git config user.email "jenkins-bot@example.com"
                            git add ${K8S_MANIFEST_FILE}
                            git commit -m "Update image to ${IMAGE_TAG}"
                            git push origin ${BRANCH_NAME}
                            """
                            }
                        }
                    }
                }
        stage ('Notification deployment') {
            steps {
                container('nextjs') {
                    script {
                        echo "Deployment to production is successful"
                    }
                }
            }
        }

        stage('Trigger Argo CD Sync to Deployment') {
            steps {
                container('nextjs') {
                    script {
                    // Trigger Argo CD sync bằng webhook hoặc CLI
                    sh """
                    argocd app sync app-test --auth-token ARGOCD_AUTH_TOKEN --server test-argo.9ten.online
                    """
                    // Hoặc, bạn có thể gọi một webhook nếu Argo CD có tích hợp webhook Git
                    }
                }
            }
        }        

}

//    post {
//         always {
//             junit 'reports/**/*.xml' // Adjust to your test report location
//             archiveArtifacts artifacts: '**/coverage/**', allowEmptyArchive: true
//             script {
//                 // Wait for SonarQube analysis to be completed
//                 timeout(time: 1, unit: 'HOURS') {
//                     waitForQualityGate abortPipeline: true
//                 }
//             }
//         }
//     }  
}
