# Check Certificate

## walk.sh

I do not know if vault client is able to print all secrets  in active `KV` type secret engines recursively. But `walk.sh` does this.

`walk.sh` scripts is a helper script that recursively print all  `secrets` inside the active `KV` type secret engines.

### Usage:
1 - First set address `export VAULT_ADDR=`

2 - Set Vault Auth method one of four methods below.

* Export VAULT_TOKEN `export VAULT_TOKEN=<token>`   `OR`
* Place VAULT token to file in your $HOME folder `$HOME/.vault_tokens`  `OR`
* Export VAULT_ROLE_ID and VAULT_SECRET_ID: `export VAULT_ROLE_ID`  `export VAULT_SECRET_ID`  `OR`
* Place `role_id` and `secret_id` to `$HOME` folder  `$HOME/.role_id` and `$HOME/.secret_id` respectively.



```bash
./walk.sh
/data/projects/exec/check-certificate$ ./walk.sh
kv/global/shell/global
kv/global/shell/infra
secret/a
secret/certs/dragon
secret/global/opsgenie/jenkins
secret/global/slack/ocp-alerts
secret/global/slack/prod
secret/global/slack/test
secret/openshift/prod
secret/openshift/prod/ingress
secret/openshift/test
```

## check-certificate.sh

`check-certificate.sh` script simply checks the `notAfter` date of TLS certificates specified in the config file. It sends a `Slack` notification, if expire date of TLS certificate is less than the `threshold`. If `threshold` is not specified in the config file, default threshold will be used which is `30 days`. Threshold specificied between `[]`.

check.txt
```txt
tls://manintheit.org:443[2m]                        # maintheit.org threshold is 2 months
tls://another.manintheit.org:443[30d]               # another.maintheit.org --> threshold is 30 days.
vault://secret/data/certs/dragon/tls.crt            # tls certificate in hashicorp vault no threshold specified, default threshold value will be considered, which is 30 days.
```

```bash
./check-certificate.sh check.txt
```


## TODO:

* check-certificate.sh --> Add additional Vault auth methods to implement.(check walk.sh)
* check-certificate.sh --> More informative messages.









