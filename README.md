# Update inputs
To update one of the inputs you can just do:
```
nix flake lock --update-input <input-name>
```

# Backend
The backend should be hosted on port `8080`.

# Deployment
## Setup
You'll want to setup all of your environment variables:
```
export RESOURCE_GROUP=
export LOCATION=
export STORAGE_ACCOUNT=
export SUBSCRIPTION=
export STORAGE_CONTAINER=
export GALLERY=
export IMAGE_NAME=nixos
export VM_NAME=
```

You can create a resource group with:
```
az group create --name $RESOURCE_GROUP --location $LOCATION
```

You can create an image gallery with:
```
az sig create --resource-group $RESOURCE_GROUP --gallery-name $GALLERY
```

In order to upload an image to the image gallery we'll need blob storage for
that.

You can create a storage account. This should give a storage account ID we can
use later.
```
az storage account create \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_ZRS \
    --encryption-services blob
```

With the CLI you will need to give yourself the storage blob data contributor
role. The scope argument should be the storage account ID from creating it.
```sh
az ad signed-in-user show --query id -o tsv | az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee @- \
    --scope "/subscriptions/$SUBSCRIPTION/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
```

You can now create a storage account container:
```sh
az storage container create \
    --account-name $STORAGE_ACCOUNT \
    --name $STORAGE_CONTAINER \
    --auth-mode login
```

It needs to end in `.vhd` for when we add it to the image gallery.
```sh
az storage blob upload --overwrite \
    --account-name $STORAGE_ACCOUNT \
    --container-name $STORAGE_CONTAINER \
    --name nixos.vhd \
    --file nixos.vhd \
    --auth-mode login
```

Now we can create an image definition. This will give an image ID in the output
we'll copy for later.
```sh
az sig image-definition create \
   --resource-group $RESOURCE_GROUP \
   --gallery-name $GALLERY \
   --gallery-image-definition $IMAGE_NAME \
   --publisher nobody \
   --offer nothing \
   --sku mySKU \
   --os-type Linux
```

The storage id for the `--os-vhd-storage-account` is the storage id we got after
creating the account.
```sh
az sig image-version create --resource-group $RESOURCE_GROUP \
    --gallery-name $GALLERY --gallery-image-definition $IMAGE_NAME \
    --gallery-image-version 1.0.0 \
    --os-vhd-storage-account /subscriptions/$SUBSCRIPTION/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT \
    --os-vhd-uri https://$STORAGE_ACCOUNT.blob.core.windows.net/$STORAGE_CONTAINER/nixos.vhd
```

Now we can create the VM.
```sh
az vm create -g $RESOURCE_GROUP -n $VM_NAME \
    --image /subscriptions/$SUBSCRIPTION/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/galleries/$GALLERY/images/$IMAGE_NAME \
    --os-disk-delete-option Delete \
    --size Standard_B2s \
    --generate-ssh-keys \
    --os-disk-size-gb 128
```

Useful options for if we're redeploying an existing VM. Also, you'll want to
take out the `--generate-ssh-keys`.
```
    --public-ip-address backend-ip \
    --ssh-key-name backend_key \
```
