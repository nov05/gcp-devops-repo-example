# Google Skills Lab - Building a DevOps Pipeline

* Lab tasks ([Google Docs](https://docs.google.com/document/d/1nIz91opc7jwgZ_yi3YOq8nS45-WG25lwb2WHZ2I_-zY/edit?usp=sharing))

  The original lab tasks are:
  
      Task 1. Create a Git repository  
      Task 2. Create a simple Python application  
      Task 3. Define a Docker build  
      Task 4. Manage Docker images with Cloud Build and Artifact Registry  
      Task 5. Automate builds with triggers  
      Task 6. Test your build changes  

  However, I created a **cloudbuild.yaml** with 4 steps:
  
      Step 1. Detect project, allowed region, allowed zones   
      Step 2. Create Docker image   
      Step 3. Create a VM instance, deploy the image, set up Nginx reverse proxy for HTTPS  
          Or re-deploy the image if instance already exsits  
      Step 4. Create firewall rules for HTTP and HTTPS traffic     

* Logs
  
2026-03-24 repo created from GCP
