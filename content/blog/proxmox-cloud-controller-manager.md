## Design

### Cluster Autoscale

#### Bare minimum
Communication with ProxMox through the API using the golang library.
Spin up node by cloning the cloud-init VM template.
Have a custom kubernetes worker template with things pre-installed.
Add node to cluster.

#### Optional Extra
Make ProxMox aware of clusters running within.

### LoadBalancer
Not sure if this is needed since MetalLB and Cilium can do L2 or L3 IP announcement.

#### Bare minimum
Communicate with HAProxy using API v2.
