#!/bin/env python3

from diagrams import Cluster, Diagram
from diagrams.aws.compute import EC2Instances
from diagrams.aws.network import Endpoint, ElbNetworkLoadBalancer, Route53HostedZone
from diagrams.aws.security import Shield

diagram_attr = {
    "pad": "0.5"
}

with Diagram("Tecton Cross-VPC Privatelink", graph_attr=diagram_attr, filename="diagram"):
    with Cluster("AWS account"):
        with Cluster("Endpoint Service VPC"):
            vpc_endpoint_service_tecton = ElbNetworkLoadBalancer("Tecton Service NLB")
            service_ec2_instances = EC2Instances("Tecton Service Instances")
            vpc_endpoint_service_tecton >> service_ec2_instances
        with Cluster("Client VPC"):
            private_hosted_zone = Route53HostedZone("Private Hosted Zone")
            sg_vpc_endpoint = Shield("Client VPC Endpoint Security Group")
            client_ec2_instances = EC2Instances("Tecton Client Instances")
            vpc_endpoint_client = Endpoint("Client VPC Endpoint")
            client_ec2_instances >> vpc_endpoint_client >> vpc_endpoint_service_tecton
