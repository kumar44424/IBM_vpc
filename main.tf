#Configuring Provider File Access

provider "ibm" {
  ibmcloud_api_key   = "zn6aEE5l022DfZMORTQXhxA0eyRu86OQb4fd8d56t11m"
  generation         = 2
  region             = "us-south"
  softlayer_username = "287523_pramod.srinivasa@in.ibm.com"
  softlayer_api_key  = "c4158fc8cc24277b8e549c71138033d8d49d92a03ac7e13b52f40d6be3189118"
}


# Creating VPC Names terraform-test
resource ibm_is_vpc "vpc1" {
  name = "terraform-test"
}

#Provides a vpc address prefix resource. This allows vpc address prefix to be created, updated, and cancelled.
resource "ibm_is_vpc_address_prefix" "vpc-test" {
  name   = "vpc-test"
  zone   = "us-south-1"
  vpc    = "${ibm_is_vpc.vpc1.id}"
  cidr   = "10.241.0.0/24"
}

# Creating Security Group named new
resource ibm_is_security_group "sg1" {
  name = "new"
  vpc  = "${ibm_is_vpc.vpc1.id}"
}

# Allow SSH incoming network traffic on port 22
resource "ibm_is_security_group_rule" "ingress_ssh_all" {
  group     = "${ibm_is_security_group.sg1.id}"
  direction = "inbound"
  remote    = "0.0.0.0/0"                       

  tcp = {
    port_min = 22
    port_max = 22
  }
}
#Allow Outbound traffic on port 80
resource "ibm_is_security_group_rule" "egress_all" {
  depends_on = ["ibm_is_floating_ip.fip1"]
  group      = "${ibm_is_vpc.vpc1.default_security_group}"
  direction  = "outbound"
  remote     = "0.0.0.0/0"

 tcp = {
    port_min = 80
    port_max = 80
  }
}

# Subnet Declaration
resource ibm_is_subnet "subnet1" {
  name = "new"
  vpc  = "${ibm_is_vpc.vpc1.id}"
  zone = "us-south-1"
  ipv4_cidr_block = "10.240.0.0/18"
}

# Provide a resource to attach security group to a network interface.
resource "ibm_network_interface_sg_attachment" "sgnic1" {
    security_group = "${ibm_is_security_group.sg1.id}"
    network_interface = "${ibm_is_instance.ins1.primary_network_interface.0.id}"
}

# Creating a Virtual Instance
resource ibm_is_instance "ins1" {
  name    = "CentOS 6"
  os_reference_code = "CENTOS_6_64"
  vpc     = "${ibm_is_vpc.vpc1.id}"
  zone    = "us-south-1"
  keys    = [""]
  profile = "cx2-2x4"

  primary_network_interface = {
    subnet          = "${ibm_is_subnet.subnet1.id}"
    security_groups = ["${ibm_is_security_group.sg1.id}"]
  }
}

# Allocating Resource Volume
resource "ibm_is_volume" "vol1" {
  name     = "new"
  profile  = "10iops-tier"
  zone     = "us-south-1"
  capacity = 100
}

#Allocating Floating IP
resource ibm_is_floating_ip "fip1" {
  name   = "new"
  target = "${ibm_is_instance.ins1.primary_network_interface.0.id}"
}

output sshcommand {
  value = "ssh root@${ibm_is_floating_ip.fip1.address}"
}


