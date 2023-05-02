/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# This script assumes that the VPCs and their subnets already exist prior to execution

# Using only for reference, not touching VPC configs
module "vpc1" {
     source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v21.0.0"
     vpc_create = false
     project_id = var.project_id
     name       = var.vpc1
}

# Using only for reference, not touching VPC configs
module "vpc2" {
    source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v21.0.0"
    vpc_create = false
    project_id = var.project_id
    name       = var.vpc2

}

module "vpn-1" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpn-ha?ref=v21.0.0"
  project_id = var.project_id
  region     = var.region
  network    = module.vpc1.self_link
  name       = "net1-to-net-2"
  peer_gateways = {
    default = { gcp = module.vpn-2.self_link }
  }
  # not sharing any custom routes, should be added to router_config if needed
  router_config = {
    asn = 64514
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64513
      }
      bgp_session_range     = "169.254.2.1/30"
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.6"
        asn     = 64513
      }
      bgp_session_range     = "169.254.2.5/30"
      vpn_gateway_interface = 1
    }
  }
}

module "vpn-2" {
  source        = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpn-ha?ref=v21.0.0"
  project_id    = var.project_id
  region        = var.region
  network       = module.vpc2.self_link
  name          = "net2-to-net1"
  # not sharing any custom routes, should be added to router_config if needed
  router_config = { 
    asn = 64513
 }
  peer_gateways = {
    default = { gcp = module.vpn-1.self_link }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64514
      }
      bgp_session_range     = "169.254.2.2/30"
      shared_secret         = module.vpn-1.random_secret
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.5"
        asn     = 64514
      }
      bgp_session_range     = "169.254.2.6/30"
      shared_secret         = module.vpn-1.random_secret
      vpn_gateway_interface = 1
    }
  }
}