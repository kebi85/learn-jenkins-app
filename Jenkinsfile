pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = 'f76227d9-ddd8-4718-abb8-207d4bd9f093'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
        REACT_APP_VERSION = "1.0.$BUILD_ID"
    }

    stages {

        stage('Docker') {
            steps {
                sh'''
                    docker build -t my-playwright .
                '''
            }
        }

        stage('Build') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    ls -la
                    node --version
                    npm ci
                    npm run build
                    ls -la
                '''
            }
        }

        stage('Tests') {
            parallel {
                stage('Unit Tests') {
                    agent {
                        docker {
                            image 'node:18-alpine'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            echo 'Unit tests'
                            test -f build/index.html
                            npm test
                        '''
                    }
                    post {
                        always {
                            junit 'jest-results/junit.xml'
                        }
                    }
                }

                stage('E2E Tests') {
                    agent {
                        docker {
                            image 'my-playwright'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            echo 'E2E tests'
                            serve -s build &
                            sleep 10
                            npx playwright test --reporter=html
                        '''
                    }
                    post {
                        always {
                            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright Local HTML Report', reportTitles: '', useWrapperFileDirectly: true])
                        }
                    }
                }
            }
        }

        stage('Deploy staging') {
            agent {
                docker {
                    image 'my-playwright'
                    reuseNode true
                }
            }
            environment {
                CI_ENVIRONMENT_URL = 'set-at-runtime-from-netlify-deploy-output'
            }
            steps {
                sh '''
                    netlify --version
                    echo "Deploying to Staging, Site ID: $NETLIFY_SITE_ID"
                    netlify status
                    netlify deploy --dir=build --json > deploy-output.json
                    CI_ENVIRONMENT_URL=$(node-jq -r '.deploy_url' deploy-output.json)
                    echo "Staging URL: $CI_ENVIRONMENT_URL"

                    echo 'E2E Staging tests'
                    npx playwright test --reporter=html
                '''
            }
            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Staging E2E HTML Report', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }

        // stage('Approve Deploy') {
        //     steps {
        //         timeout(time: 1, unit: 'HOURS') {
        //             input message: 'Ready to deploy?', ok: 'Deploy'
        //         }
        //     }
        // }

        stage('Deploy prod') {
            agent {
                docker {
                    image 'my-playwright'
                    reuseNode true
                }
            }
            environment {
                CI_ENVIRONMENT_URL = 'https://wondrous-nougat-1703e4.netlify.app'
            }
            steps {
                sh '''
                    netlify --version
                    echo "Deploying to Production, Site ID: $NETLIFY_SITE_ID"
                    netlify status
                    netlify deploy --dir=build --prod

                    echo 'E2E Prod tests'
                    npx playwright test --reporter=html
                '''
            }
            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Prod E2E HTML Report', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }
    }
}
