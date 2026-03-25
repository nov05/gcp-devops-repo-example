# Google Skills Lab - **Building a DevOps Pipeline**

* **Lab tasks** 

  The original lab tasks are:
  
      Task 1. Create a Git repository  
      Task 2. Create a simple Python application with Flask  
      Task 3. Define a Docker build  
      Task 4. Manage Docker images with Cloud Build and Artifact Registry  
      Task 5. Automate builds with triggers  
      Task 6. Test your build changes    

  Instead of creating VM instances manually, I created a **cloudbuild.yaml** with 4 steps. Once a change is pushed to the repo, the trigger will run, and **Cloud Build** will take care of everything. In the end, you’ll be able to access the "Hello, Build Trigger" webpage of the app in your browser via HTTP or HTTPS.   
  
      Step 1. Detect the project, allowed region, and allowed zones      
      Step 2. Build the Docker image        
      Step 3. Create a VM instance, deploy the image, and configure an Nginx reverse proxy for HTTPS   
          Or re-deploy the image if the instance already exists      
      Step 4. Set up firewall rules to allow HTTP and HTTPS traffic       

  ✅ For detailed instructions, please refer to [the **Google Docs** file](https://docs.google.com/document/d/1nIz91opc7jwgZ_yi3YOq8nS45-WG25lwb2WHZ2I_-zY).

* **Logs**

2026-03-25 demo video created  
2026-03-24 repo created from GCP
