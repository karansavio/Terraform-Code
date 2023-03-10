# This is the Sapia Terraform Exercise. Author: Karan Choudhary

Steps:

Step1: Run `terraform init` on the root folder

Or run `terraform init -backend-config=backend.hcl` and change the region in the `key` field to deploy the s3 bucket to another region

Run `terraform plan` prior to applying the resource changes

Run `terraform apply` to apply the changes to the default region `ap-southeast-2` (NOTE: You may need to apply the changes again (`terraform apply`) for the autoscaling changes to take effect)

Once resources have been deployed to AWS and testing is completed, run: `terraform destroy` from the root folder to destroy all the resources.


# Verify the Load Balancer DNS is working and WAF Rules

- On the AWS console, proceed to EC2 and select Load Balancer and copy the DNS name and paste it on the browser. NGINX server would show it running successfully.

- For the WAF configuration and rules, proceed to WAF and select Web ACLS -> Owasp Top 10, you will see the chart highlighting the requests based on the rules defined. Click on Rule Groups to see the Rate-Limit-Rule.

# Mock Attack

For the Mock Attack (please refer to the MockAttackScreenshot.png) :

1. Initial Setup: A Wordpress login form was created that is hosted on the webserver which in turn runs on an ec2 instance. The Wordpress page was then linked to the database to create users with credentials that could potentially be found in the rockyou.txt file.

2. Web Attack Tools: BurpSuite Community version, rockyou.txt list

3. Web attack: 

    - Start the temporary project on BurpSuite Community, migrate to the proxy tab and open the BurpSuite browser. Alternatively, you can use the 'foxyproxy' plugin to intercept traffic.
    - Load the WordPress login page on the BurpSuite browser. 
    - Click on 'Intercept On' and login with the username created in the database and a random password. 
    - Select the attack technique as 'Cluster Bomb' to find given usernames with weak passwords through permutations/combinations.
    - Select the username and password parameters manually and add it as the variables to be bruteforced.
    - Send the information to the Intruder by right clicking and selecting 'Send to intruder' option.
    - For Usernames list (1st parameter): Provide the 2 usernames manually, as in this case was wp_jordan & wp_daniel.
    - For Password list (2nd parameter): Upload the rockyou.txt list.
    - Click on 'Start Attack' and keep a close eye on the 'Status' code and 'Length' columns.
    - As per the screenshot on the bottom-left, we have identified the potential password for wp_jordan & wp_daniel.
      Status code 302 ==> the page was redirected as the user could successfully login.


# Future Considerations

- I would segregate the VPC, Load Balancers and ECS Services as seperate modules to the WAF rules to demonstrate a better TF structure for a productionised environment. This would help make the code easier to maintain and update the code over time.

- I would add a WAF Shield as an additional protection layer to the OWASP attacks which would help with improving the security of the web application that meets compliance requirements without compromising on performance and reliability.

- I would deploy the code to remote location to allow for a better source to allow for optimal utilization of terragrunt to assist with deploying to multi-regions