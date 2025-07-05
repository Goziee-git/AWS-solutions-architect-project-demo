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
🛜![internet](images/image.png)
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

