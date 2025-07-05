## THREE TIER ARCHITECTURE PROJECT

# WHAT IS A THREE-TIER-ARCHITECTURE

### PRE-REQUISITES

### STEP1 : CREATE A VPC AND SUBNET AS WELL AS ROUTING AND SECURITY GROUPS FOR YOUR WORKLOAD
- Go to “Your VPCs” from the VPC service on the AWS management console and click on the orange “Create VPC” button
- create a vpc here and give it a name. You are free to make your own name or follow along with the one put here. choose ```vpc only```
- Give it a ```192.168.0.0/16``` CIDR block.
- Choose ```No IPv6 CIDR Block``` 
- Leave Tenancy as ```Default```
- optionaly choose a Tag
- click on the orange button to create VPC
![vpc-image](images/vpc.png)
**CREATING SUBNETS**
- To create your subnets go to Subnets on the left hand side of the VPC service and click on it
- Add your VPC ID to where it asks ```$(VPC-ID)```
- Assign it a name letting you know what it is your first public subnet ```Public-Subnet```
- Put it in any availability zone ```us-east-1a``` and give it a CIDR of ```192.168.1.0/24```
- leave others as Default and click on create. (This is going to be your public Subnet)
- Add a second subnet and name it ```Private-Subnet-1``` or something to let you know it is your first private subnet
- Put it in the same availability zone ```us-east-1a``` as the first subnet you made and give it a ```subnet-CIDR``` of ```192.168.2.0/24```
- Add a third subnet and assign a name letting you know it is the second private subnet ```Private-subnet-2```you will be making
- Put it in the same availability zone ```us-east-1a``` as your first public subnet and give it a ```subnet-CIDR``` of ```192.168.3.0/24```
- Add a fourth and final subnet and give it a name letting you know it is the third private subnet ```Private-Subnet-3```
- Put it in a **different availability zone**, ```us-east-1b``` from the rest of your subnets ```Private-Subnet-3``` and give it a ```subnet-CIDR``` of ```192.168.4.0/24```
![subnet-resource-image](images/subnet-resource-map.png)
- Default route tables will be setup by AWS to route traffic to the subnets. 
- Allocate an Elastic IP address by going to Elastic IPs on the left hand side and click ```Allocate Elastic IP address```
- Make sure the ```Network-border-group``` is the same as the region you've been creating your resources and Leave all other settings as default then press ```“Allocate”```. You can optionally add a name tag if you wish though this is not necessary
![elastic-ip](images/elastic-ip.png)
**INTERNET GATEWAY**
- Now create an internet gateway and attach it to the VPC by going to Internet Gateways on the left hand side and clicking ```“Create Internet Gateway”```
- After creating the Internet Gateway, at the upper right corner, click on actions, in the drop-down menu, choose ```Attach VPC``` and select the VPC for your resources, click on the yellow button selecting```Attach Internet Gateway```.
![internet-gateway](images/internet-gateway.png)

📲**NAT GATEWAY**
- Create a NAT Gateway by clicking on Nat Gateways on the left hand side and then clicking ```Create NAT Gateway```
- Give it a name like this ```my-nat-gateway``` and assign it to a **public subnet** such as ```Public-Subnet```which you created earlier.
- Select ```Connectivity type``` as **Public**
- Click the drop down for Elastic IPs and click the one you created previously.
- Click ```Create NAT gateway```

®️**ROUTE TABLES**
- Create Route Tables by first heading to “Route Tables” on the left hand side
- Click ```Create route table```, Name the route table ```my-route-table```, select the VPC you've been using for your resources and hit the yellow button to ```Create Route table```
- Make a second route table naming it ```Private-route-table``` and assign your VPC to it.
- Now associate your subnets with their respective route table
- Click on the public route table and click on ```Subnet association``` next to “Details”
- Click on ```Edit subnet associations``` and select the ```Public-Subnet``` created, select ```Associate Subnet`` to associate the public route table with the public subnet
- Do same for the private route table, associate it with the private subnets created earlier
- Now add a route to our public route table to get access to the internet gateway
- Click on ```Routes``` next to ```Details``` and click ```Edit routes```
- Add a new route having a destination of anywhere ```0.0.0.0``` and a target of your ```internet gateway``` with your ```Internet-gateway-ID``` and click ```Save changes```
- To edit routes for the private table, Go to edit the routes of the private table
- Add a route to the private table that has a destination of anywhere and a target of your Nat gateway that you made earlier

🔐 **SECURITY GROUPS**
- Now to create our security groups (One for our bastion host, web server, app server, and our database) we will head to Security Groups on the left and click ```Create security group```
- Give it a name and description letting you know it is for a bastion host
- Assign your VPC to it by selecting your VPC-ID in the VPC section
- add the following ```inbound rules``` to the bastion host security group
   ***HTTP: TCP/80 : 0.0.0.0/0 (anywhere)
   HTTPS: TCP/443 : 0.0.0.0/0 (anywhere)
   SSH: TCP/22 : 0.0.0.0/0 (anywhere)***
![bastion-host](images/bastion-host-sg.png)


- Create another security group ```web-server-security-group```
- Give it a description letting you know it is for a Web server
- Assign your VPC to it
- Give it the same inbound rules as the Bastion Host security group
![webserver-sg](images/webserver-sg.png)

- Create another security group
- Give it a name ```app-server-security-group``` and description letting you know it is for an app server
- Assign your VPC to it
- Give it an inbound rule for All ICMP-IPv4 with a source of your web server SG and another inbound rule for SSH with a source of your bastion host SG
- Create one final security group 
- Give it a name ```db-sg``` description letting you know it is for a database server
- Assign your VPC to it
- Give it two inbound rules both for MYSQL/Aurora and give one of them a source of your app server SG and the other one a source of your bastion host SG
- Go back to your bastion host inbound rules and add one more for MYSQL/Aurora and a source of your database SG
- Go back to your web server inbound rules and add one more for All ICMP - IPv4 and a source of your app server SG
Go back to your app server inbound rules and add one more for MYSQL/Aurora and a source of your database SG and then an HTTP and HTTPS rule both with a source of 0.0.0.0/0

