# Terraform_AWS_Web_Instance_Using_EFS
>**Overview**
* [web_instance.tf](https://github.com/Icyshaman/Terraform_AWS_Web_Instance_Using_EFS/blob/master/web_instance.tf) is a terraform file which will perform following task:
    
    * Creates a key and a security group which allow port 22 and port 80.
    
    * Launch EC2 instance using key and security group created by code itself.

    * Launch one volume (EFS) and mount that volume into /var/www/html.

    * Copy the github repo code (mentioned in terraform file) into /var/www/html.

    * Create S3 bucket and copy/deploy images from github repo into the S3 bucket and change the permission to public readable.

    * Create a CloudFront using S3 bucket.
***
>**Steps to use**
* Copy [web_instance.tf](https://github.com/Icyshaman/Terraform_AWS_Web_Instance_Using_EFS/blob/master/web_instance.tf) to your local system.

* Using Command Prompt navigate to the folder where [web_instance.tf](https://github.com/Icyshaman/Terraform_AWS_Web_Instance_Using_EFS/blob/master/web_instance.tf) is stored.

* Run command **aws configure --profile < profile_name >**. (Requires AWS CLI to be installed and path need to be set)

* Enter AWS Access Key ID, AWS Secret Access Key, Default region name, Default output format.

* Run command **terraform init** to download all the plugins required.

* Run command **terraform apply** to create the infrastructure.

* Run command **terraform destroy** to destroy the infrastructure.
***
