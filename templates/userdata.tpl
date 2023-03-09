MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
export B64_CLUSTER_CA=${certificate_authority_data}
export API_SERVER_URL=${cluster_endpoint}
sudo /etc/eks/bootstrap.sh ${cluster_name} --kubelet-extra-args '${kubelet_extra_args}' --b64-cluster-ca $B64_CLUSTER_CA --apiserver-endpoint $API_SERVER_URL --dns-cluster-ip ${dns_ip} ${bootstrap_extra_args}
--//--
