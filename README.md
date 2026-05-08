# Serverless AWS Fargate App with CI/CD, RDS, and Blue-Green Deployment

## 🚀 Project Overview
This project demonstrates a complete, fully automated DevOps workflow. It provisions a serverless infrastructure on AWS using **Terraform**, deploys a Python Flask application connected to a MySQL database, and uses **Jenkins** to automate the CI/CD pipeline. It also features zero-downtime **Blue-Green Deployments** (via ECS Rolling Updates) and real-time monitoring using **Grafana** and AWS CloudWatch.

## 🛠️ Tech Stack
* **Infrastructure as Code (IaC):** Terraform
* **Cloud Provider:** AWS (VPC, Application Load Balancer, ECS Fargate, RDS MySQL, CloudWatch, IAM)
* **CI/CD:** Jenkins, GitHub
* **Containerization:** Docker, Docker Hub
* **Application:** Python (Flask, mysql-connector-python)
* **Monitoring:** Grafana

---

## 🎯 What I Built (and Why)

### 1. Serverless Infrastructure (The "What")
I used Terraform to build a secure network (VPC, Public Subnets, Internet Gateway) from scratch. Inside this network, I deployed an **AWS Application Load Balancer (ALB)** to distribute traffic and an **Amazon RDS (MySQL)** instance to serve as a persistent database. The application itself runs on **AWS ECS Fargate**, meaning there are no EC2 instances or underlying servers to manage. 

### 2. The Goals (The "Why")
* **Zero-Downtime Deployments:** By utilizing ECS Rolling Updates, I achieved a Blue-Green deployment workflow. New containers are spun up and verified by the ALB before the old ones are terminated.
* **Data Persistence:** Separating the application (Fargate) from the database (RDS) ensures that when containers are destroyed or updated, user data remains intact.
* **Cost Control:** I implemented a parameterized Jenkins pipeline with an `apply` and `destroy` choice. This allows me to spin up the entire infrastructure when needed and completely tear it down with one click to avoid unnecessary AWS charges.
* **Full Automation:** Every code push to the `main` branch triggers Jenkins to fetch the code, run Terraform, build the Docker image, push it to Docker Hub, and update the ECS service automatically.

---

## 🚧 Challenges and Troubleshooting

Building this pipeline wasn't without its hurdles. Here are the main difficulties I encountered and how I solved them:

1.  **Jenkins & Docker Hub Authentication:**
    * *Issue:* The pipeline kept failing at the `docker login` stage, throwing unauthorized errors despite having the correct Personal Access Token.
    * *Solution:* I realized Jenkins was mishandling the token because the credential type was set to "Username with password". Changing the credential type to "Secret text" and passing it securely via Groovy variables resolved the issue.
2.  **Pipeline Synchronization (Local vs. SCM):**
    * *Issue:* While debugging, I switched Jenkins to run a local "Pipeline script" instead of pulling from Git. When I pushed new code (the "GREEN" version), Jenkins was still building the old local files.
    * *Solution:* Re-configured Jenkins to pull the `Jenkinsfile` from SCM (GitHub) and ensured my local Git repository was fully committed and synced with the remote branch.
3.  **Grafana & AWS CloudWatch Integration:**
    * *Issue:* Grafana wasn't displaying the CPU utilization metrics from AWS ECS. The graphs were completely empty.
    * *Solution:* The issue was IAM permissions. I had to attach the `CloudWatchReadOnlyAccess` policy to the AWS user associated with Grafana. After configuring the correct dimensions (`ClusterName` and `ServiceName`) in the Grafana query, the metrics populated perfectly, allowing me to visually verify the CPU spikes during the Blue-Green container switch.

---

## 💻 How to Run This Pipeline

1.  Configure Jenkins with the necessary credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `fargate-docker-token`, `DB_PASSWORD`).
2.  Trigger a build in Jenkins using **Build with Parameters**.
3.  Select **`apply`** to provision the infrastructure and deploy the app.
4.  Access the application via the ALB DNS name output by Terraform.
5.  Select **`destroy`** to clean up and delete all AWS resources.