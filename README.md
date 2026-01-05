When you just need a cluster, who you gonna call?

Not me, probably. But if for some reason you did, here you go.


This spins up a kubernetes cluster via vagrant and virtualbox using:

* containerd
* Ubuntu (tested, but maybe others if you fix package names et al)
* kubeadm
* tls enabled
* ~~calico~~ weave CNI



# Requirements

vagrant (and the puppet plugin, and racc plugin if you're on Windows)
Virtualbox
Cognac (optional)
kubernetes CLI on your jumpbox (the machine you're running these commands, usually!)
helm on your jump box as well (Or you can do these manually)

# How to use

5 days would normally be a lot of time to make this more robust but only tested against the specific defaults referenced below. Deviation is up to you to debug unless I get paid to make this nicey nice.

## Set up the VMs

This was scoped to using virtualbox and vagrant. It's an oldie, but a goodie.

I tried to leverage opentofu but that's really better built for cloud providers.  Still, I left the notes behind in the ./brain_dump.md file.

With vagrant you'll also need to install the puppet plugin, so kick off the below command after installing the required software above:
```bash
vagrant plugin install puppet
```

If you're dealing with a fractured soul and getting errors like the below, you'll also want to install the `racc` plugin with the same command above.

```bash
Vagrant failed to initialize at a very early stage:

The plugins failed to load properly. The error message given is
shown below.

cannot load such file -- racc/parser.rb
```

Finally, once you've got it bootstrapped, you can run the `vagrant up` command.

The expectation is:
* 3 nodes (1 controlplane, 2 workers)
* a join_command.sh and kubeconfig file in the project root directory.

Set up your kubeconfig to point to where you've cloned down the module:


Powershell
```powershell
$env:KUBECONFIG="C:\path\to\this\project\kubeconfig"
```

Or your *nix shell of choice.

The initial setup exposes the admin kubeconfig for playing the admin role for the following steps.
It also generates the certificates on the worker nodes.  In case you want to play around with a 2nd user.

################################################
The following steps are manual due to jumping between something I'd put in an automated workflow and user actions
the automated workflow skipped mostly because I couldn't decide how I wanted to approach it.
################################################

Next we need helm chart to create the namespace that our users/developers will be allowed to deploy apps to.

We need some custom resource definitions so adding them here:

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.2/cert-manager.crds.yaml
```


Then let's add the roles, namespace, and binding for the user to use later:


```bash
helm install userspace ./charts/userspace --namespace userspace --create-namespace
  ```

And let's stack on the cert-manager:

```bash
helm install cert-manager oci://quay.io/jetstack/charts/cert-manager --version v1.19.2 --namespace cert-manager --create-namespace
```


This sets up the namespace, the role needed, and now our mock user Bob (that's you!) can submit their certificate for approval by the admin (that's also you!)

For the following steps, choose one of the two workers as these certs were generated on the host.
To do this we'll leverage vagrant ssh commands.  The examples below we'll just use k8s-worker1, but you can
adjust as desired.



Copy the `user_cert_template.yaml` to `user_cert.yaml` and then modify file to include the base64 encrypted cert file (i.e. `k8s-worker1base64.txt`).  Example below:

```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: developer
spec:
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ2JUQ0NBVlVDQVFBd0tERVNNQkFHQTFVRUF3d0pjMjl0WlY5MWMyVnlNUkl3RUFZRFZRUUtEQWx1WjJsdQplQzFoY0hBd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUUMwQlkzN2ZRQUN6b0NhCndITTE1ZWZ3U2RVTlltSERnTU8wa1h3dEhjT0xudXJBcHE0eVA5amdKU09oZnltekNMTm55c2ozc0s0SW4wVkoKc3pEN2xzZldQRFRiYmdhZnZBY0VtZzAwRHM5ejBqU3ZVRkNmcllPSUl6K1BkNUxXQ0xSYzMycGpodXJ6WU9HdQpTd3BNWmxTMkVEMk9LaERnQXhkcUVSZWNlL3J4MDIzNFJ1WjNZYVlSNk8wWVpya2JZRWsvR1VtOFFCblR2KzhvCjRUUFJLTXZ0WDhLcmFueTNsWGdYN2hnaElXMkY2dXlodWFtYUNWSFdPRXpiNm5Sa3VxYkgrbGxKN2cvcjFuL24KVUplbWN0Si81ZHI1WEhzM01IMjNVWXcrSUJ5SEl0eHZmMDZ2amJ6MTYwZEd5Q0FaWmNWdDZQbmdNSHEvZk9SQQpkaGtxOHlMSEFnTUJBQUdnQURBTkJna3Foa2lHOXcwQkFRc0ZBQU9DQVFFQXNKWUVzMjYvWDUwSWEzVFBFUG1TClVQVTRKR1VQdTNiRkJWZGIwOU9yRmRsVERkQ3V1dlRMLzNER3BDYTBadk9YcUdkS1Jpc1dkQXdRSHZ6VUNTeEUKOEtrQ2hWSFEreDZxUzNycnJRZDJNdzl2TUtYUnAwN0VMQlplMjRuRUU5dW1XTUtLMlA0dmRoTTQvV0xvRjBZaQp2NjBETjRTTTdqdEdkVENEKzNDL0xqVE5ybnJRU0tEaVQrTWVlV2VIQTVKMlFSNmdiSFlKM1p5Z3FmaHYzS3kwCkNqZnlNS1hxbmIvbmZVa2JBRlJTb3o2UjkvalhGV3NYeTM2WmpQL1dpYVorVStpbG8xSWQ2V2pqakFWTjBrUGUKMnRCc1pkR0RPWTRyNGdLQkRXVXRXdXhObFBPZDVXcSs5L0Y2RnZDZUVQUEV5L3RIeHI2M2dmQkp2a0hvcTduWApJQT09Ci0tLS0tRU5EIENFUlRJRklDQVRFIFJFUVVFU1QtLS0tLQo=
  signerName: kubernetes.io/kube-apiserver-client
  usages:
    - client auth
```

Then you'll want to submit it (You can use the admin or the user scoped kubeconfig for this!)

```bash
kubectl apply -f user_cert.yaml
```

Then as the admin kubeconfig, approve the cert request!

```bash
kubectl certificate approve bob
```

Now you need to do some annoying manual tasks that really should've been automated but will be labelled with a legacy TODO:

```bash
kubectl get csr bob -o jsonpath='{.status.certificate}' > base64.crt
```

Then you need to remove the single quotes in this file.  If on *nix, very easy with the above tr command.
If on windows, you can `wsl tr` or just modify the file.  We want to get rid of the `'` otherwise base64 won't parse it.

Once it's removed, you can run the below command:

```bash
vagrant ssh k8s-worker1 -c "/vagrant/vagrant_scripts/decrypt_cert.sh"
```

#### WARNING: This will lock out your admin access from the kubeconfig, but you can always reclaim it from the controlplane node. Or setup the admin context to switch back to. ####

Now we can create the user kubeconfig from the admin config:

```bash
kubectl config set-credentials bob --client-certificate=developer.crt --client-key=k8s-worker1some_user.key
```

Then we can easily swap between user and admin as needed for this environment:

```bash
kubectl config set-context bob@kubernetes --cluster=kubernetes --user=bob
```

Now, as our user, bob, we will apply a helm chart that builds their little nginx page

```bash
helm install hello-nginx ./charts/nginx_open \
  --namespace userspace
```



Next task is to setup a user, and grant said user access to deploy apps in their own namespace.  There we'll deploy the nginx.



## Nice to haves
If I had more time/was realistically building this for general consumption, I'd add in "error" checking/handling per: [k8s docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin)