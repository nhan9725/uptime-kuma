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
        CACHE_DIR = '/home/jenkins/.cache/yarn' // Cache directory on the Jenkins agent

    }

    stages {
// no need , because define on configure 
//        stage('Git Checkout SCM') {
//            steps {
//                checkout scm
//            }
//    }

        stage('Cache Calculate Checksum if Installed Dependencies') {
            steps {
                container('nextjs') {
                    script {
                        // Calculate the checksum for package.json
                        CACHE_KEY = sh(
                            script: 'md5sum package.json | awk \'{ print $1 }\'',
                            returnStdout: true
                        ).trim()
                        echo "Calculated Checksum: ${CACHE_KEY}"

                        // Define the path to the cache file
                        def cachePath = "${env.CACHE_DIR}/dependencies-${CACHE_KEY}.tar"

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
        // stage('Install Dependencies') {
        //     steps {
        //         script {
        //             def cacheHit = false
        //             if (fileExists("dependencies-${CACHE_KEY}.tar")) {
        //                 echo "Cache hit, extracting dependencies..."
        //                 sh "tar -xf dependencies-${CACHE_KEY}.tar"
        //                 cacheHit = true
        //             }

        //             if (!cacheHit) {
        //                 echo "Cache miss, running yarn install..."
        //                 sh 'yarn install'
        //                 sh "tar -cf dependencies-${CACHE_KEY}.tar node_modules"
        //             }
        //         }
        //     }
        // }                

        stage('Unit Install and Build') {
            steps {
             container('nextjs') {
                script {
                    
                    // Install dependencies using Yarn
               //     sh 'yarn install'
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

        stage('Unit Test') {
            steps {
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
                    } catch (Exception e) {
                        echo "Error during testing: ${e.message}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }          
  
        stage('Code Coverage') {
            steps {
                script {
                    try {
                        // Record and publish code coverage reports using JaCoCo
                        recordCoverage tools: [[parser: 'JACOCO']],
                            id: 'jacoco', name: 'JaCoCo Coverage',
                            sourceCodeRetention: 'EVERY_BUILD',
                            qualityGates: [
                                [threshold: 60.0, metric: 'LINE', baseline: 'PROJECT', unstable: true],
                                [threshold: 60.0, metric: 'BRANCH', baseline: 'PROJECT', unstable: true]
                            ]
                    } catch (Exception e) {
                        echo "Error during code coverage: ${e.message}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        } 

        stage('SonarQube analysis') {
        steps {
            script {
                scannerHome = tool 'sonar-test'// must match the name of an actual scanner installation directory on your Jenkins build agent
            }
            withSonarQubeEnv('SonarCloud') {// If you have configured more than one global server connection, you can specify its name as configured in Jenkins
            sh """
                ${scannerHome}/bin/sonar-scanner \
                -Dsonar.organization=${SONAR_ORG} \
                -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                -Dsonar.sources=. \
                -Dsonar.host.url=https://sonarcloud.io    
                -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
                -Dsonar.coverage.jacoco.xmlReportPaths=coverage/cobertura-coverage.xml
            """
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
