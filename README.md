# Tools for generating kafka ssl certificates

Thank to https://github.com/confluentinc/confluent-platform-security-tools

## How to run

- Edit following environment variables in `gen_ssl_auto.sh` file

```KEYSTORE_FILENAME="kafka.keystore.jks"
VALIDITY_IN_DAYS=3650
DEFAULT_TRUSTSTORE_FILENAME="kafka.truststore.jks"
TRUSTSTORE_WORKING_DIRECTORY="output/truststore"
KEYSTORE_WORKING_DIRECTORY="output/keystore"
CA_CERT_FILE="ca-cert"
KEYSTORE_SIGN_REQUEST="cert-file"
KEYSTORE_SIGN_REQUEST_SRL="ca-cert.srl"
KEYSTORE_SIGNED_CERT="cert-signed"

COUNTRY="vn"
STATE="hcm"
OU="trisda"
CN="da.tris.vn"
LOCATION="hcm"

KEYSTORE_PASS="zVdjkq0a21fY"
TRUSTSTORE_PASS="5DrVkh7YemZb"
```

- Run `./gen_ssl_auto.sh`, enter `y` to generate truststore and `n` to not

- Generated ssl in `output` folder