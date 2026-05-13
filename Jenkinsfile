pipeline {
  agent any

  environment {
    ARM_CLIENT_ID       = credentials('ARM_CLIENT_ID')
    ARM_CLIENT_SECRET   = credentials('ARM_CLIENT_SECRET')
    ARM_TENANT_ID       = credentials('ARM_TENANT_ID')
    ARM_SUBSCRIPTION_ID = credentials('ARM_SUBSCRIPTION_ID')
  }

  stages {

    stage('Checkout') {
      steps {
        git url: 'https://github.com/Naiyyar-git/terraform-databricks-examples.git',
            branch: 'main'
      }
    }

    stage('Phase 1 · Init') {
      steps {
        dir('examples/adb-lakehouse') { sh 'terraform init' }
      }
    }
    stage('Phase 1 · Plan') {
      steps {
        dir('examples/adb-lakehouse') { sh 'terraform plan -out=tfplan-infra' }
      }
    }
    stage('Phase 1 · Approval') {
      steps {
        input message: 'Review the Phase 1 plan above. Approve to apply?',
              ok: 'Apply Phase 1'
      }
    }
    stage('Phase 1 · Apply') {
      steps {
        dir('examples/adb-lakehouse') { sh 'terraform apply -auto-approve tfplan-infra' }
      }
    }

    stage('Phase 2 · Plan') {
      steps {
        dir('examples/adb-lakehouse') { sh 'terraform plan -out=tfplan-workspace' }
      }
    }
    stage('Phase 2 · Approval') {
      steps {
        input message: 'Review the Phase 2 plan. Approve to apply?',
              ok: 'Apply Phase 2'
      }
    }
    stage('Phase 2 · Apply') {
      steps {
        dir('examples/adb-lakehouse') { sh 'terraform apply -auto-approve tfplan-workspace' }
      }
    }

    stage('Phase 3 · Init') {
      steps {
        dir('examples/adb-unity-catalog-basic-demo') { sh 'terraform init' }
      }
    }
    stage('Phase 3 · Plan') {
      steps {
        dir('examples/adb-unity-catalog-basic-demo') { sh 'terraform plan -out=tfplan-uc' }
      }
    }
    stage('Phase 3 · Approval') {
      steps {
        input message: 'Review the Phase 3 plan. Approve to apply?',
              ok: 'Apply Phase 3'
      }
    }
    stage('Phase 3 · Apply') {
      steps {
        dir('examples/adb-unity-catalog-basic-demo') { sh 'terraform apply -auto-approve tfplan-uc' }
      }
    }

  }

  post {
    success { echo 'All phases applied successfully.' }
    failure { echo 'Pipeline failed — check stage logs above.' }
    aborted { echo 'Aborted at approval gate. Nothing was applied.' }
  }
}
