# hyperswitch_poc
Deploy Hyperswitch in Argo + Helm + k3s provisioned through Ansible / Terraform

## Tunnel cluster

```shell
cd ./terraform/vultr
export EXTERNAL_IP=$(terraform output -raw instance_ipv4)
ssh debian@$EXTERNAL_IP "cat /home/debian/.kube/config" > ~/.kube/config
ssh -L 6443:localhost:6443 -N -vvv debian@$EXTERNAL_IP
```

## Migrate

```shell
# setup tunnel with Kube Forwarder
export PASSWORD=$(kubectl get secrets/hyperswitch-postgresql -n hyperswitch --template={{.data.password}} | base64 -d)
export POSTGRES_PASSWORD=$(kubectl get secret hyperswitch-postgresql -n hyperswitch --template="{{index .data \"postgres-password\"}}" | base64 -d)
export DATABASE_URL=postgres://hyperswitch:$PASSWORD@localhost:5432/hyperswitch
export DATABASE_URL=postgres://postgres:$POSTGRES_PASSWORD@localhost:5432/hyperswitch
cargo install just
cargo install diesel_cli --no-default-features --features "postgres"
git clone https://github.com/juspay/hyperswitch.git
cd hyperswitch
just migrate
```

## Quick start

```shell
curl --location 'http://localhost:8080/accounts' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--header 'api-key: test_admin' \
--data-raw '{
  "merchant_id": "merchant_1729050982",
  "locker_id": "m0010",
  "merchant_name": "NewAge Retailer",
  "merchant_details": {
    "primary_contact_person": "John Test",
    "primary_email": "JohnTest@test.com",
    "primary_phone": "sunt laborum",
    "secondary_contact_person": "John Test2",
    "secondary_email": "JohnTest2@test.com",
    "secondary_phone": "cillum do dolor id",
    "website": "https://www.example.com",
    "about_business": "Online Retail with a wide selection of organic products for North America",
    "address": {
      "line1": "1467",
      "line2": "Harrison Street",
      "line3": "Harrison Street",
      "city": "San Fransico",
      "state": "California",
      "zip": "94122",
      "country": "US",
      "first_name":"john",
      "last_name":"Doe"
    }
  },
  "return_url": "https://google.com/success",
  "webhook_details": {
    "webhook_version": "1.0.1",
    "webhook_username": "ekart_retail",
    "webhook_password": "password_ekart@123",
    "webhook_url":"https://webhook.site",
    "payment_created_enabled": true,
    "payment_succeeded_enabled": true,
    "payment_failed_enabled": true
  },
  "sub_merchants_enabled": false,
  "parent_merchant_id":"merchant_123",
  "metadata": {
    "city": "NY",
    "unit": "245"
  },
  "primary_business_details": [
    {
      "country": "US",
      "business": "default"
    }
  ]
}'
```
