# Using a custom private registry for the agent docker images
OpsVerse supports the usage of custom private container registry to host the container images required by the OpsVerse agent helm chart.

* Pull and push the container images to your private registry
* Use an updated version of `image-override-values.yaml` in the `helm install` command to refer to your private registry

## Pushing images to the private registry


## K8s Helm Image Override
The `image-override-values.yaml` file can be used to override the default registry path of docker images with a custom registry path.