# Overview:

We needed a way to automate the deployment of [Streamsets](https://streamsets.com), an open source data streaming tool. We chose Streamsets because it is active, has a good community, and was easy to integrate into Salesforce.  We chose [terraform](https://www.terraform.io/) as our deployment tool because we were already using it for another project and like many aspects about it.

Our main concerns in deployment were around security, since Streamsets would be manipulating data from various systems and we wanted to lock things down. We mitigated security in the following ways:

- Created a VPC to house all infrastructure
- Added a public subnet with a load balancer to handle incoming web traffic
- Added a private subnet with no public IP to house the streamsets instance
- Added a bastion server to get access to the private streamsets server
- Used an [open source tool](https://github.com/widdix/aws-ec2-ssh) from [widdix](https://github.com/widdix) to manage access to both servers

If you are concerned with security, you'll want to do at least the following two things:

- Lock down the `allowed_ip_addresses` in [variables.tf](variables.tf) to your office/local IP CIDR
- Change the users in the [streamsets user configuration](bin/streamsets/form-realm.properties) to the users you want. More info on this is found in the [Streamsets user guide](https://streamsets.com/documentation/datacollector/latest/help/#datacollector/UserGuide/Configuration/Authentication.html#task_nsz_lp4_1r).

# Network Diagram

![AWS Network Diagram](resources/pipeline-network-diagram.png?raw=true "Network Diagram")

# Getting Started

You will need to install two command line tools. I recommend installing them through [Homebrew](https://brew.sh):

```sh
$ brew install awscli
$ brew install terraform
```

[`awscli`](https://aws.amazon.com/cli/) is for interacting with AWS from the command line, and [`terraform`](https://www.terraform.io) is for managing infrastructure.

## SSL

Create a free AWS SSL Certificate through their [Certificate Manager](https://aws.amazon.com/certificate-manager/)

Then, copy the ARN and replace the value in [variables.tf](variables.tf) for `ssl_cert_arn`

## Command Line

Make sure you have an AWS account with an access key and secret access key. To configure your credentials for the command line:

```sh
$ aws configure
AWS Access Key ID [None]: [insert your Access Key ID here]
AWS Secret Access Key [None]: [insert your Secret Access Key here]
Default region name [None]: us-east-1
Default output format [None]: json
```

## How to build/deploy

Create a private/public key for provisioning if you don't already have one:

`ssh-keygen -t rsa -b 4096 -C "your_email@example.com"`

Initialize the terraform state:

`terraform init`

Deploy:

`terraform apply -var 'key_name=<your_private_key_name>' -var 'public_key_path=<path_to_your_public_key.pub>'`

This should show you all of the resources it will create. Say 'yes' if you want to create them for realz. The output of the creation will be the HTTPS path to your streamsets instance, and the IP address of your bastion.

## Authentication

### SSH and Database access

We are using an open source library to connect IAM accounts for SSH access. All of our servers and databases do not accept SSH traffic, with 1 exception. We have a 'bastion' server which acts as a gateway to the rest. This means that nothing is accessible to the outside world except for this server and the Load Balancer. Both of them only accept traffic coming from specific IP addresses.

If you want to connect to the bastion, you will need to:

- generate an ssh key (or use one you've already created)
  - `ssh-keygen -t rsa -C "your_email@example.com"`
- Upload the *public* key to IAM in the AWS console. AWS -> IAM -> YourUsername -> Security Credentials -> Upload SSH public key
- Add the ssh key to your ssh agent `ssh-add -K ~/.ssh/id_rsa` where `id_rsa` is the name of your private key file. You may need to do this every time you start up your terminal unless you [add it to your configuration files](https://apple.stackexchange.com/questions/48502/how-can-i-permanently-add-my-ssh-private-key-to-keychain-so-it-is-automatically).

#### Connecting to a private server

- Find the bastion public IP address in the aws console
- Connect to the bastion using `ssh -A yourawsusername@bastion.public.ip.address`
  - The `-A` forwards your ssh agent to the bastion so that you can make the second jump
- From the bastion, connect to the private server using `ssh yourawsusername@private.server.ip.address`

### Bash scripts

We provision the servers using bash scripts in the `bin` folder. The [bastion.tf](bastion.ftf) file contains the local and remote commands used to build and run them properly. It gets a little tricky because the streamsets instance doesn't have a public IP so terraform has to provision that server through the bastion.

## HTTPS

Streamsets will run in https mode. If you don't want the nagging "Not Secure" message, point your DNS for the AWS certificate you created earlier to the ELB that is outputted from the script.

## Cleanup

If you want to destroy everything, run

`terraform destroy -var 'key_name=<your_private_key_name>' -var 'public_key_path=<path_to_your_public_key.pub>'`

Note: if it gives you an error about not being able to delete roles, just run it again. This is a known issue for this repo.

## Layout

`variables.tf` holds all of the parameters. AWS access will be pulled from your local config

`outputs.tf` tells terraform what to spit out after applying the plan

`aws.tf` holds the main aws configuration (not much)

`iam_ssh.tf` has the role configurations necessary to use the [IAM ssh login project](https://github.com/widdix/aws-ec2-ssh)

`bastion.tf` configures the server that we will use to get SSH access to the private instances

`streamsets.tf` configures the instances in the private subnet (streamsets)

`public.tf` configures the resources in the public subnet (load balancer)

`vpc.tf` configures the VPC, subnets, and routing tables

The files in the `./bin` folder are scp'd over to the web server and used for bootstrapping and installing streamsets
