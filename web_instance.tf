provider "aws"{
	region	= "ap-south-1"
	profile	= "vikas"
}

# Generate a key
resource "tls_private_key" "p_key"{
	algorithm	= "RSA"
	rsa_bits	= 4096
}

# Create a key pair
resource "aws_key_pair" "key_pair"{
	key_name	= "mykey1"
	public_key	= tls_private_key.p_key.public_key_openssh
}

# Create a security group (Allow port 22, port 80 and port 2049)
resource "aws_security_group" "s_group_ssh_http_nfs"{
	name		= "allow_ssh_http_nfs"
	description 	= "Allow SSH, HTTP and NFS inbound traffic"
	vpc_id		= "vpc-4e7d6126"
	
	ingress{
		from_port	= 22
		to_port		= 22
		protocol	= "tcp"
		cidr_blocks	= ["0.0.0.0/0"]
	}
	
	ingress{
		from_port	= 80
		to_port		= 80
		protocol	= "tcp"
		cidr_blocks	= ["0.0.0.0/0"]
	}

	ingress{
		from_port	= 2049
		to_port		= 2049
		protocol	= "tcp"
		cidr_blocks	= ["0.0.0.0/0"]
	}
	
	egress{
		from_port	= 0
		to_port		= 0
		protocol	= "-1"
		cidr_blocks	= ["0.0.0.0/0"]
	}

	tags = {
		Name	= "allow_ssh_http_nfs"
	}	
}

# Launch an instance
resource "aws_instance" "web_instance"{
	ami		= "ami-0447a12f28fddb066"
	instance_type	= "t2.micro"
	key_name	= "mykey1"
	security_groups = ["allow_ssh_http_nfs"]

	connection{
		type		= "ssh"
		user		= "ec2-user"
		private_key	= tls_private_key.p_key.private_key_pem
		host		= aws_instance.web_instance.public_ip
	}
	
	provisioner "remote-exec"{
		inline = [ "sudo yum install httpd git amazon-efs-utils nfs-utils -y", 
			   "sudo systemctl restart httpd",
			   "sudo systemctl enable httpd" ]
	}

	tags = {
		Name	= "webinstance"
	}
}

# Create an EFS
resource "aws_efs_file_system" "efs_storage"{
	creation_token	= "efs shared data"
	
	tags = {
		Name	= "efs1"
	}
}

# Provide an EFS mount target
resource "aws_efs_mount_target" "efs_mount"{
	depends_on	= [ aws_instance.web_instance, aws_efs_file_system.efs_storage ]
	file_system_id	= aws_efs_file_system.efs_storage.id
	subnet_id	= aws_instance.web_instance.subnet_id
	security_groups = [ aws_security_group.s_group_ssh_http_nfs.id ]
}

# Mount the volume
resource "null_resource" "vol_mount"{
	depends_on	= [ aws_efs_mount_target.efs_mount, ]

	connection{
		type		= "ssh"
		user		= "ec2-user"
		private_key	= tls_private_key.p_key.private_key_pem
		host		= aws_instance.web_instance.public_ip
	}

	provisioner "remote-exec"{
		inline = [ "sudo mount ${aws_efs_file_system.efs_storage.id}:/ /var/www/html",
			   "sudo echo ${aws_efs_file_system.efs_storage.id}:/ /var/www/html efs defaults,_netdev 0 0 >> sudo /etc/fstab",
			   "sudo git clone https://github.com/Icyshaman/terraform_test1.git /var/www/html" ]
	}
}

# Create S3 bucket
resource "aws_s3_bucket" "object_storage1"{
	bucket		= "bucket1223334444333221"
	force_destroy	= true
	acl		= "public-read"
	
	provisioner "local-exec"{
		when	= destroy
		command	= "RD /S /Q terraform-task1"			    
	}

	provisioner "local-exec"{
		command	= "git clone https://github.com/Icyshaman/terraform_test1.git terraform-task1"
	}
		
	versioning{
		enabled	= true
	}
	
	tags = {
		Name	= "object_storage1"
	}
}

# Upload file in S3 bucket
resource "aws_s3_bucket_object" "object_upload"{
	key	= "img1.jpg"
	bucket	= aws_s3_bucket.object_storage1.bucket
	source	= "terraform-task1/Image/tree.jpg"
	acl	= "public-read"
}

# Create Cloudfront
resource "aws_cloudfront_distribution" "cloudfront1"{
	origin{
		domain_name	= aws_s3_bucket.object_storage1.bucket_regional_domain_name
		origin_id	= "s3-${aws_s3_bucket.object_storage1.bucket}"
		
		custom_origin_config{
			http_port		= 80
			https_port		= 80
			origin_protocol_policy	= "match-viewer"
			origin_ssl_protocols	= [ "TLSv1", "TLSv1.1", "TLSv1.2" ]
		}
	}

	enabled	= true

	default_cache_behavior{
		allowed_methods		= [ "DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT" ]
		cached_methods		= [ "GET", "HEAD" ]
		target_origin_id	= "s3-${aws_s3_bucket.object_storage1.bucket}"
		
		forwarded_values{
			query_string	= false
		
			cookies{
				forward	= "none"
			}
		}
	
		viewer_protocol_policy	= "allow-all"
		min_ttl			= 0
		default_ttl		= 3600
		max_ttl			= 86400
	}

	restrictions{
		geo_restriction{
			restriction_type	= "none"
		}
	}
	
	viewer_certificate{
		cloudfront_default_certificate	= true
	}
}

	
