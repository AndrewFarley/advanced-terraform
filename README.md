# Terraform Advanced
This discusses advanced terraform usage

## Author
Created by Farley  <br>
<farley@olindata.com> <farley@neonsurge.com>


Terraform Security

Terraform just uses the AWS API via the Go SDK
There are no terraform-specific security aspects to consider or discuss other than keeping in mind that your Terraform will be able to read/modify/update/DESTROY your infrastructure
Terraform is usually be given a wide-open permissions to AWS and other cloud providers because of the numerous API calls across the board it will need to be able to do its job
Managing and maintaining a minimalist terraform-specific role is extremely complicated.  For good example of how complicated it is look at the minimalist cloudformation role that was created for the Grab Terraform CI/CD stack.  That role "barely" allows software to deploy lambdas, imagine trying to manage/maintain this for your terraform stack.  Almost every change (besides minor tweaks) you made to terraform would require modification to the role.
Because of this, when CI/CD is implemented, special consideration must be placed on the server(s) that have access to run terraform apply.  For Grab, I recommend considering a separate Jenkins runner that is only to be used by Terraform that has an Instance Role that grants full permissions.



The power of Infrastructure as Code

The idea and power of terraform is to share the responsibility of some of your operations to outside of your Ops team.  Think of it, as open-sourcing your infrastructure.  Right now, your infrastructure is a "black box" whose sole responsibility is on your operations team.  A developer can't come in and on their own AWS sandbox deploy an entire "stack" to get one or many of your services up and running.  All the effort, all the dependency, is on your Ops team to pre-setup everything, build Jenkins pipelines, deploy autoscaling groups and load balancers, etc.  And even when that's all done, all the responsibility is still on Ops, if a dev team decides they want a new service (say, SNS, or SQS, or Memcached), they need to send a ticket to Ops to create and set this up manually.  When you "open" the infrastructure up, you allow for cooperate infrastructural iteration, and you have more eyes on things so you can find bugs/flaws more easily.  And finally, you can standardize between your environments.  In my brief musings at the Grab AWS Console I saw a significant number of differences between your configurations on staging and production.  Some are massive differences that would cause upwards of 1000% differences in performance between the two, making any comparative performance testing useless.




Terraform workflow
Terraform best-practices
Using Terraform modules, and creating reusable terraform modules
Using existing infrastructure with terraform (aka, terraform import)
Shared State / Shared Variables?
Continuous Integration / Pipelining Terraform
user-data, before/after creation scripts, inline scripts
Integration with other languages and tools
Using an existing stack’s state as an input for another stack
