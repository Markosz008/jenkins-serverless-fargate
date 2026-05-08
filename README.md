# Serverless AWS Fargate App with CI/CD, Blue-Green Deployment, and WAF Security

## 🚀 Project Overview
This project demonstrates a complete, highly available, and secure DevOps workflow. It provisions a serverless infrastructure on AWS using **Terraform**, deploys a Python Flask application connected to a MySQL database, and uses **Jenkins** to automate the CI/CD pipeline. 

The architecture features zero-downtime **Blue-Green Deployments** (via ECS Rolling Updates), real-time monitoring with **Grafana**, dynamic **Auto Scaling**, and robust security using **AWS WAF**. Furthermore, pipeline executions trigger automated **Discord notifications**.

## 🛠️ Tech Stack
* **Infrastructure as Code (IaC):** Terraform
* **Cloud Provider:** AWS (VPC, ALB, ECS Fargate, RDS MySQL, CloudWatch, WAF, Auto Scaling, IAM)
* **CI/CD:** Jenkins, GitHub, Discord Webhooks
* **Containerization:** Docker, Docker Hub
* **Application:** Python (Flask, mysql-connector-python)
* **Monitoring:** Grafana, AWS CloudWatch

---

## 🎯 Architecture & Features

### 1. Serverless Compute & Data Persistence
The application runs on **AWS ECS Fargate**, eliminating the need for server management. An **Application Load Balancer (ALB)** routes traffic to the containers, while user data is persistently stored in a private **Amazon RDS (MySQL)** instance.

### 2. Zero-Downtime Deployments (Blue-Green)
By utilizing ECS Rolling Updates, new containers are spun up and verified by the ALB before the old ones are terminated. This ensures the application remains online during updates.

### 3. Dynamic Auto Scaling
The infrastructure is designed to handle traffic spikes. I implemented an **ECS Target Tracking Scaling Policy** that continuously monitors the `ECSServiceAverageCPUUtilization`. If CPU usage exceeds 70%, AWS automatically provisions additional Fargate containers to handle the load, scaling back down when traffic subsides.

### 4. Advanced Security (AWS WAF)
To protect the database from malicious inputs, an **AWS WAF (Web Application Firewall)** is attached directly to the ALB. It actively inspects incoming requests and blocks **SQL Injection (SQLi)** attempts (e.g., `' OR 1=1 --`) returning a 403 Forbidden response to attackers.

### 5. Full Pipeline Automation & Notifications
* A parameterized Jenkins pipeline allows for one-click **Apply** (provision & deploy) or **Destroy** (teardown to save costs).
* Every code push to the `main` branch triggers the pipeline.
* **Post-build Notifications:** Utilizing Jenkins credentials and `curl`, the pipeline sends real-time success or failure alerts directly to a **Discord channel**.

---

## 🚧 Challenges and Troubleshooting
* **Docker Hub Authentication in Jenkins:** Solved by transitioning from standard username/password to passing a Personal Access Token (PAT) as a Secret Text via Groovy environment variables.
* **Grafana CloudWatch Metrics:** Resolved empty graphs by configuring IAM policies (`CloudWatchReadOnlyAccess`) for the Grafana user and defining exact dimension mapping (`ClusterName`, `ServiceName`).
* **WAF Validation Errors:** Encountered Terraform API errors when applying WAF rules due to non-ASCII characters in the AWS resource description. Fixed by strictly adhering to AWS regex constraints for descriptions.

---

## 💻 How to Run This Pipeline

1.  Configure Jenkins with the necessary credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `fargate-docker-token`, `DB_PASSWORD`, `DISCORD_WEBHOOK`).
2.  Trigger a build in Jenkins using **Build with Parameters**.
3.  Select **`apply`** to provision the infrastructure, deploy the app, and receive a Discord alert.
4.  Select **`destroy`** to automatically tear down all AWS resources and prevent billing.
