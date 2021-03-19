#! /bin/bash
# execution example:
#   SSH_KEY="~/.ssh/..." ./deploy.sh

terraform apply

BASTION_IP=$(terraform output bastion_host_public_ip)
DOCKERLAB_IP=$(terraform output docker_lab_private_ip)

echo "SSH_KEY = ${SSH_KEY}"
echo "BASTION_IP = ${BASTION_IP}"
echo "DOCKERLAB_IP = ${DOCKERLAB_IP}"
echo "SSH config file ="
cat ~/.ssh/config

if [[ -f ~/.ssh/config && ! -z $BASTION_IP && ! -z $DOCKERLAB_IP ]]; then

cat << EOF > ~/.ssh/config
    Host randysaws-main-vpc-bastion-host
        HostName $BASTION_IP
        User ec2-user
        IdentityFile $SSH_KEY
        ProxyCommand none
    Host randysaws-main-vpc-docker-lab
        HostName $DOCKERLAB_IP
        User ec2-user
        IdentityFile $SSH_KEY
        ProxyCommand ssh randysaws-main-vpc-bastion-host -W %h:%p
EOF

echo "new SSH config file ="
cat ~/.ssh/config

fi