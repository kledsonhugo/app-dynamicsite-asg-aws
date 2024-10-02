# ORCHESTRATOR

module "network" {
  source = "./modules/network"
}

module "compute" {
  source          = "./modules/compute"
  vpc_id          = module.network.vpc_id
  vpc_cidr        = module.network.vpc_cidr
  sn_pub_az1a_id  = module.network.sn_pub_az1a_id
  sn_pub_az1c_id  = module.network.sn_pub_az1c_id
  sn_priv_az1a_id = module.network.sn_priv_az1a_id
  sn_priv_az1c_id = module.network.sn_priv_az1c_id
  ec2_ami         = "051f8a213df8bc089"
}
