# Variables
RESOURCE_GROUP="rg-tsbdemo-ram"
LOCATION="southindia"
VNET_NAME="vnet-tsbdemo"
SUBNET1_NAME="subnet1"
SUBNET2_NAME="subnet2"
VM1_NAME="vm1-tsbdemo"
VM2_NAME="vm2-tsbdemo"
VM_SIZE="Standard_B1ms"  # Allowed VM size
IMAGE="Canonical:0001-com-ubuntu-minimal-jammy:minimal-22_04-lts-gen2:latest"
ADMIN_USER="azureuser"
SSH_KEY_PATH="$HOME/.ssh/azure_vm_key"  # Path to store the SSH key

# Create Resource Group if not exists
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Virtual Network with two Subnets
az network vnet create --resource-group $RESOURCE_GROUP --name $VNET_NAME --location $LOCATION --address-prefix "10.0.0.0/16" \
    --subnet-name $SUBNET1_NAME --subnet-prefix "10.0.1.0/24"

az network vnet subnet create --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name $SUBNET2_NAME --address-prefix "10.0.2.0/24"

# Generate SSH Key (if not already present)
if [ ! -f "$SSH_KEY_PATH" ]; then
    ssh-keygen -t rsa -b 2048 -f $SSH_KEY_PATH -N ""
    echo "SSH key generated at $SSH_KEY_PATH"
else
    echo "Using existing SSH key at $SSH_KEY_PATH"
fi

# Create VM1 with NIC in Subnet1
az network nic create --resource-group $RESOURCE_GROUP --name "${VM1_NAME}-nic" --vnet-name $VNET_NAME --subnet $SUBNET1_NAME

az vm create --resource-group $RESOURCE_GROUP --name $VM1_NAME --image $IMAGE --size $VM_SIZE \
    --admin-username $ADMIN_USER --ssh-key-values "$SSH_KEY_PATH.pub" --nics "${VM1_NAME}-nic" 

# Create VM2 with NIC in Subnet2
az network nic create --resource-group $RESOURCE_GROUP --name "${VM2_NAME}-nic" --vnet-name $VNET_NAME --subnet $SUBNET2_NAME

az vm create --resource-group $RESOURCE_GROUP --name $VM2_NAME --image $IMAGE --size $VM_SIZE \
    --admin-username $ADMIN_USER --ssh-key-values "$SSH_KEY_PATH.pub" --nics "${VM2_NAME}-nic"

# Get Public IPs
VM1_IP=$(az vm list-ip-addresses --name $VM1_NAME --resource-group $RESOURCE_GROUP --query "[].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)
VM2_IP=$(az vm list-ip-addresses --name $VM2_NAME --resource-group $RESOURCE_GROUP --query "[].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)

echo "============================================================="
echo "VMs $VM1_NAME and $VM2_NAME created successfully!"
echo "SSH key path: $SSH_KEY_PATH"
echo "To connect to VM1: ssh -i $SSH_KEY_PATH $ADMIN_USER@$VM1_IP"
echo "To connect to VM2: ssh -i $SSH_KEY_PATH $ADMIN_USER@$VM2_IP"
echo "============================================================="
