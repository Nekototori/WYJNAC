This just contains notes I wrote that I dumped here for transparency.

Mostly this is just iteration/deadends/experiments that failed.

None of this will make sense, but enjoy the juice. Maybe with a large amount of alcohol.

#####

Download your image of choice. By default we use `jammy-server-cloudimg-amd64.vmdk` so you'll need to download it yourself from [this link](https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-amd64.ova)  



This is designed assuming all VMs run on the same version/kernel.  Can k8s work across different kernels and even arch? Yes. It is a hell `taint`ed with lots of headaches and maybe job security of the not-so-good kind.

Place the image in the images directory and update the ../opentofu/variables.tf and update the `image_name` variable.


```
ubuntu-22.04-server-cloudimg-amd64.ova
```
