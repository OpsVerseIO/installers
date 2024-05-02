# Using a custom private registry for the agent docker images
OpsVerse supports the usage of custom private container registry to host the container images required by the OpsVerse agent helm chart.

* Pull and push the container images to your private registry
* Use an updated version of `image-override-values.yaml` in the `helm install` command to refer to your private registry

## Pushing images to the private registry

* Ensure that you have the authentication done for both the Opsverse Registry from where the images will be pulled and the Private Registry where the images will be pushed.

For authenticating on the Opsverse Harbor Registry use the following command - 
`docker login registry.devopsnow.io/private`
`docker login registry.devopsnow.io/public`
Login for both the `private` and `public` directory.

For authenticating on Private ECR registry use the following command - 
`aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com`

* Export the CONTAINER_TARGET_REGISTRY and CONTAINER_REGION in the terminal as follows - 
export CONTAINER_TARGET_REGISTRY=<aws_account_id>.dkr.ecr.<region>.amazonaws.com
export CONTAINER_REGION=<region>
export REPOSITORY_PREFIX=<your-repository-prefix>

* You can also add a repository prefix that will be appended to your repositoryg name. To do this, just change the variable string name "REPOSITORY_PREFIX" present in the script as follows - 

* Run the image-pull-push.sh script file 
sh image-pull-push.sh
NOTE - If you encounter any error with the above command, use bash to execute the image-pull-push.sh

## K8s Helm Image Override
The `image-override-values.yaml` file can be used to override the default registry path of docker images with a custom registry path.