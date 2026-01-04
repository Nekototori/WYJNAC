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

```bash
helm install userspace ./charts/userspace --namespace userspace --create-namespace
  ```

This sets up the namespace, the role needed, and now our mock user Bob (that's you!) can submit their certificate for approval by the admin (that's also you!)

Modify the `user_cert.yaml` file to include the cert file.  Example below:

```yaml



Next task is to setup a user, and grant said user access to deploy apps in their own namespace.  There we'll deploy the nginx.



## Nice to haves
If I had more time/was realistically building this for general consumption, I'd add in "error" checking/handling per: [k8s docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin)