# fedora-server-bootc
Configs and automation for deploying Fedora bootc based servers in my home lab

# Links

Bootc docs
https://osbuild.org/docs/bootc/

config.toml file
https://github.com/osbuild/bootc-image-builder/?tab=readme-ov-file#-build-config

Blueprint reference
https://osbuild.org/docs/user-guide/blueprint-reference

# Build the container

```
sudo podman build --squash -t fedora-bootc-testserver:latest . 

```



# Generate the bootable image


```
sudo podman run --rm -it \
--privileged \
--security-opt label=type:unconfined_t  \
--pull=newer \
-v ./config.toml:/config.toml:ro \
-v .:/output \
-v /var/lib/containers/storage:/var/lib/containers/storage \
quay.io/centos-bootc/bootc-image-builder:latest \
--type qcow2 \
--rootfs btrfs \
--local \
localhost/fedora-bootc-testserver:latest
```

# Push to my local registry

```
sudo podman push --tls-verify=false localhost/fedora-bootc-testserver:latest <registry host>:5000/fedora-bootc-testserver:latest
```
