# Terraform Advanced
This discusses advanced terraform usage

## Author
Created by Farley  <br>
<farley@olindata.com> <farley@neonsurge.com>


## The power of Infrastructure as Code (IaC)

The idea and power of terraform is to share the responsibility of some of your operations to outside of your Ops team.  Think of it, as open-sourcing your infrastructure.  When infrastructure is a "black box" whose sole responsibility is on your operations team.  A developer can't come in and on their own AWS sandbox deploy an entire "stack" to get one or many of your services up and running.  All the effort, all the dependency, is on your Ops team to pre-setup everything, build CI/CD pipelines, deploy autoscaling groups and load balancers, ensuring an application loads.  And even when that's all done, all the responsibility is still on ops to keep it working despite any changes or requirements that may come to that stack, if a dev team decides they want a new service (say, SNS, or SQS, or Memcached), they need to inform and wait for ops to create and set this up manually.  When you "open" the infrastructure up, you allow for cooperative infrastructural iteration, and you have more eyes on things so you can find bugs/flaws more easily.  And finally, you can standardize configuration between your environments.  You can't imagine how many times I look at someone's AWS console and see their configurations differ so wildly between dev/staging/production.  Which is fine, if it's intentional (for cost-saving), but then any metrics gathered about your scalability on anything except your live environment may be wildly incorrect.


## Terraform Security

Terraform just uses the provider's API, in AWS's case, it uses the AWS API via the Go SDK embedded in terraform (well, now in a binary module)
There are no terraform-specific security aspects to consider or discuss other than keeping in mind that your Terraform will be able to read/modify/update/DESTROY your infrastructure
Terraform is usually be given a wide-open permissions to AWS and other cloud providers because of the numerous API calls across the board it will need to be able to do its job
Managing and maintaining a minimalist terraform-specific role is extremely complicated.  For good example of how complicated it is look at the minimalist cloudformation role that was created recently for the Terraform CI/CD stack.  That role "barely" allows software to deploy lambdas, imagine trying to manage/maintain this for your terraform stack.  Almost every change (besides minor tweaks) you made to terraform would require modification to the role.
Because of this, when CI/CD is implemented, special consideration must be placed on the server(s) that run terraform.  I recommend considering a separate Jenkins runner that is only to be used by Terraform that has an Instance Role that grants full permissions.


## Creating and using Terraform modules, and creating reusable terraform modules

Most modules use a simple file hierarchy, such as...
```
module_name:
  output.tf    (this defines the outputs of this module, which can be used by parents which include this module)
  variables.tf (this defines inputs of this module, some of which can be mandatory)
  main.tf      (this and all other files are for the "meat" of the module)
```
Creating reusable modules needs to keep in mind that a user of a module may have one or many of various things, such as security groups.  Often a module will come with some minimalist configuration that sets up basic access, and then lets/makes you implement the rest in your terraform code.  You generally want to think of, and create modules as if they were public and published on your github, so everyone can use them.  Nothing in them should be private, everything in them (where possible) should be configrable, overridable, etc.  When authoring modules, you often start small, and allow for your immediate needs to be overridden.  Then as a module gets more adoption, you add more inputs/outputs as needed.

DEMO, see code, and comments herein


## Terraform Gotchas

Terraform doesn't have the concept of conditional statements, meaning, it does not (yet) have "if" or or loop type statements.  It has a very rudimentary count object which allows you to create 0-x number of a specific object, populating that object with different values from a list or map depending on which count it is on, but not all objects support count (only most resources).  This design choice provides a bit of friction and frustration for a typical programmer coming into the terraform world who would prefer to do something like...
```
if ($stage = 'dev') {
  # Put terraform code to deploy a ec2 instance as a bastion host here
} else if ($stage = 'live') {
  # Put terraform code to peer our VPC to our production management vpc and setup a VPN connection for more security
}
```
My company spoke to a senior architect working on Terraform recently (October 2017) who said that conditionals are under development and will be coming relatively soon because of the extremely high demand for them.  But for now, you have to do a bit of trickery to accomplish logic similar to the above.

A good article about the topic: https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9

An example on how to use count is here: https://github.com/terraform-providers/terraform-provider-aws/tree/master/examples/count
And in the codebase in web-v1-multiple


## Integration with other languages and external tools

You can locally integrate with other tools such as Ansible to be able to jump into and finish setting up instances automatically.  You can utilize the variables stored in or generated from Terraform to be used in your CLI command.  Keep in mind, such integrations will need to support "waiting" for SSH to become available, because EC2 reports starting instances and they still take a while to fully provision (1-2 mins usually) and if you need user_data that you specified to run, you will need to wait even longer by running some command in ansible that checks if userdata completed running.

```
resource "null_resource" "example1" {
  provisioner "local-exec" {
    command = "ansible-playbook --extra-vars server_ip=${aws_instance.web.public_ip}"
  }
  depends_on = ["${aws_instance.web}"]
}
```


## Templating

Templating is a way to modify scripts/files with variables from terraform before using them locally or remotely.  This is a great way to generate config files with your static/internal IP addresses or hostnames of resources such as RDS, or static servers, or things like ELB hostnames.

See demo in web-v1-templating


## However, modules do not support "iteration/count"...

As apparent in the sample above, if we wanted to deploy two webservers, we would need two stanzas with the ec2instance module.  There are some creative hacks out there to work around this using splits and joins and making modules that are specifically designed for multiplexing themselves.  For more information on this limitation, please see the following links...

https://serialseb.com/blog/2016/05/11/terraform-working-around-no-count-on-module/
https://github.com/hashicorp/terraform/issues/953

And see the codebase example web-v2-multiple


## Terraform Workflow / Pipelining Terraform / CI/CD

The power of infrastructure as code is the ability to pipeline it.  Keep in mind, this isn't just code that you're modifying, it's basically your entire infrastructure.  
Some project choose to have their terraform code for their service sitting inside their code repository, and utilized automatically by a pipeline.  And yet others choose to keep this code out of a code repository to keep the focus of repositories more focused on a singular task.  This is usually highly dependent on a company's project size, infrastructure, deployment scenarios, etc.
With terraform, you will generally want to test every modification scenario 3 times.
  - First, you'll make changes to terraform yourself, as a developer, and run that terraform apply modification to a sandbox type environment, allowing you to iterate quickly and make the necessary infrastructure modifications.
  - Second, you'll probably commit this and want to run your code through some type of End-To-End (e2e) type environment that does the terraform modifications and then runs a barrage of software/service specific integration tests, to ensure your software and your infrastructure are healthy.  This can be manual or fully automated, but should be fully automated.  This should still be a sandbox type environment, incase of some accidental resource management leakage between stacks (see notes about using proper env/region naming) 
  - Third (optional) you'll want to deploy to staging.  In some companies, a staging-type environment is a more public-facing type environment which you can do some real-world tests against, and possible have integrators or external contractors test against.
  - Fourth, deploy to production
When pipelining and fully automating terraform, some people like to make a terraform pipeline "pause" if it detects any changes (aka, the output from terraform plan).  The reason being, that if it detects changes, possibly either someone has manually modified an environment, and you, the deploy-master, should review that change before applying it incase it will cause some downtime or incase someone needs to modify the terraform to add that modification OR this new version of your code requires modifications to your infrastructure.  And the nature of that can cause downtime if not considered carefully.


## Terraform best-practices

All configurable elements should be pulled out into variables.  NEVER hard-code anything.  Terraform has data sources to pull data from just about anywhere.
All elements should be modularized where possible, making your IaC.
You pretty much ALWAYS want to run `terraform plan` before running `terraform apply`
Make sure to TAG all resources that you can, especially helpful for large/shared sandbox environments
For local/rapid development, local state is fine, but for anything in production, ALWAYS use remote/shared state
When using S3 as remote state, ALWAYS turn on s3 file versioning.  Incase something "bad" happens and your remote state gets wiped/modified/corrupt.
Create all resources with names and tags that explain exactly what that resource is for/from.  Common tags include....
env = std/prd/dev/farley        # The environment name of a resource, good for doing tag-based billing
Terraform = true                # So someone knows this resource is managed by Terraform
Owner = farley@olindata.com     # This is so if someone does an audit (Eg: for keeping billing costs down) they know who to ask about a technical resource
Name = <env>-<service_label>-<unique_id>  # This helps easily see what this object is in the AWS console without having to look at other tags.  Add more data here if desired
Service = <projectname>         # For a company that runs microservices, or nunmerous projects in a single stack, having unique project/service names helps track down per-project billing and resources
Warning: CERTAIN resources are global, such as IAM users / IAM profiles / Instance Roles.  When creating resources that are global, you should include the region name in their Name definition.  This helps facilitate a multi-region deployment of your stack without causing conflict.  You generally should be able to deploy a stack multiple times in the same region (with different 'env' names), and then you should be able to deploy to a different region with the same env name as you had in another region.

Good article to read:
https://github.com/BWITS/terraform-best-practices


## To user-data or not to user-data

Terraform can be used to completely bring up an instance without having to have a separate AMI build pipeline with userdata.  It is bad-practice to have an exhaustive user-data script on an autoscaler instance though, as then your autoscaling will be delayed for as long as configuration of the server takes on top of the time Amazon takes to spin up servers.  For static instances this is fine though, and can be quite useful in fact to easily bring up a cluster of more static servers (such as DB servers, Vault, etc).  Use your best judgement and AWS best practices where it applies to your usage of Terraform.


## Before and after scripts / Inline scripting

Terraform can allow for some really advanced integrations with external softwares through the use of inline scripts, and hooks.

DEMO (DynamicIP sample terraform code)



## State modification

Two kinds, "importing" and "rm"

When importing existing objects from AWS, you'll be doing an `terraform import`.  In-order to import, you must have already-defined the resource in a .tf file.  Import modifies the state file, and associates an object in terraform (in a .tf file) with an object you specify in that provider.  For example...

```
main.tf
resource "aws_instance" "web" {
  ...
}

# terraform import aws_instance.web i-abcd1234
```

Removing stuff from terraform intentionally

Removing stuff from terraform can be helpful, such as "forgetting" that we setup an RDS server so that we can keep the old database around to dump the data from to migrate to a new one.  Same goes for "forgetting" an EC2 instance.  Modifying state in this fashion is never really something that is done by any automation or CI/CD stack, and is often utilized when heavy modification of an existing infrastructure is taking place but requires zero-downtime.  An example of this kind of modification would be migrating from using EC2 instances with your application on it to using docker containers with ECS.  These scenarios are rare and specialized and rarely automated, they are simply documented as part of an "update guide" when there is critical/breaking/non-CI-friendly changes that would affect uptime to a production environment.

```
terraform state rm aws_instance.web
```

DEMO



## Shared State

Shared state is a collaborative way to work on a infrastructre/stack together with other developers or other tools.  Every time your terraform modifies anything, it stores that "state" in a remote place.  State storage includes Consul, S3, and others.
Mentioned above in best-practices, for local/rapid development using local state is fine, but for anything in production, ALWAYS use remote/shared state
When using S3 as remote state, ALWAYS turn on s3 file versioning.  Incase something "bad" happens and your remote state gets wiped/modified/corrupted.
It's easy to enable, all you do is define where you want the remote state stored, then run `terraform init`.

Example remote config:
```
terraform {
  backend "s3" {
    bucket = "testing-new-s3-bucket"
    key    = "terraform"
    region = "eu-west-1"
  }
}
```

Please see demo: vpc-v3-remote-state



## Shared Variables???

So once thing you may have noticed, that a deployed terraform stack uses variables.  If we have shared state, and if you run the same terraform that I have with different variables, it will probably completely destroy almost every element and re-create it.  This is not cool at all.  This is one of those features that they sell as a "enterprise" or "pro" feature of terraform.  You don't _need_ them, but, you totally do need them.  You generally don't want to commit variables, what a lot of people do (including myself) is have a wrapper or a pre/post terraform script that pushes and pulls the local variables along-side the remote state.  I have a not-yet-open-sourced script or two that does this and automated the whole process.  I will be working in my free time over the next week or two to open source and will recommend/promote its usage to you.



## Using an existing stack’s state as an input for another stack

When stacks get extremely large, they get very hard to update, and can become more delicate and you may be less likely to update them for fear of them breaking.  Terraform supports using various data sources, one such data source is a S3 bucket.  And it supports parsing the "state" file that terraform itself pushes.  So, this design allows for you to deploy stacks that cascade dependencies on other stacks.  You can deploy a "VPC" stack that your entire production cluster uses, for example.  And then a completely separate stack for your ECS cluster and various apps on ECS, which reads variables from your VPC stack to know its ID and CIDR and such.  And then a completely separate stack could offer another service that offers some logging and data analytics, and perhaps another that adds a monitoring server/cluster.  A great example here, would be an ELK cluster.  AN ELK cluster inside a VPC is often used by ALL services in the VPC to spit logs into, but you wouldn't want each service trying to deploy/manage that service.  So you use a stack for your ELK cluster, and in all your services, you refer to the ELK cluster's remote state to determine the IP address (for example) of how to reach the servers.

Please see demo: web-v1-using-shared-remote-state


