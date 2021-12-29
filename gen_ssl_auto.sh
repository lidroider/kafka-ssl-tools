#!/usr/bin/env bash

set -eu

# SET ENVIRONMENT VARIABLES

KEYSTORE_FILENAME="kafka.keystore.jks"
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

function file_exists_and_exit() {
  echo "'$1' cannot exist. Move or delete it before"
  echo "re-running this script."
  exit 1
}

if [ -e "$KEYSTORE_WORKING_DIRECTORY" ]; then
  file_exists_and_exit $KEYSTORE_WORKING_DIRECTORY
fi

if [ -e "$CA_CERT_FILE" ]; then
  file_exists_and_exit $CA_CERT_FILE
fi

if [ -e "$KEYSTORE_SIGN_REQUEST" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST
fi

if [ -e "$KEYSTORE_SIGN_REQUEST_SRL" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST_SRL
fi

if [ -e "$KEYSTORE_SIGNED_CERT" ]; then
  file_exists_and_exit $KEYSTORE_SIGNED_CERT
fi

if [ -e "$KEYSTORE_SIGNED_CERT" ]; then
  file_exists_and_exit $KEYSTORE_SIGNED_CERT
fi





echo
echo "Welcome to the Kafka SSL keystore and truststore generator script."

echo
echo "First, do you need to generate a trust store and associated private key,"
echo "or do you already have a trust store file and private key?"
echo
echo -n "Do you need to generate a trust store and associated private key? [yn] "
read generate_trust_store

trust_store_file=""
trust_store_private_key_file=""

if [ "$generate_trust_store" == "y" ]; then
  if [ -e "$TRUSTSTORE_WORKING_DIRECTORY" ]; then
    file_exists_and_exit $TRUSTSTORE_WORKING_DIRECTORY
  fi

  mkdir -p $TRUSTSTORE_WORKING_DIRECTORY
  echo
  echo "OK, we'll generate a trust store and associated private key."
  echo
  echo "First, the private key."
  echo

  openssl req -new -sha256 -x509 -keyout $TRUSTSTORE_WORKING_DIRECTORY/ca-key \
    -out $TRUSTSTORE_WORKING_DIRECTORY/$CA_CERT_FILE -days $VALIDITY_IN_DAYS -nodes \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$OU/CN=$CN" 

  trust_store_private_key_file="$TRUSTSTORE_WORKING_DIRECTORY/ca-key"

  echo
  echo "Two files were created:"
  echo " - $TRUSTSTORE_WORKING_DIRECTORY/ca-key -- the private key used later to"
  echo "   sign certificates"
  echo " - $TRUSTSTORE_WORKING_DIRECTORY/ca-cert -- the certificate that will be"
  echo "   stored in the trust store in a moment and serve as the certificate"
  echo "   authority (CA). Once this certificate has been stored in the trust"
  echo "   store, it will be deleted. It can be retrieved from the trust store via:"
  echo "   $ keytool -keystore <trust-store-file> -export -alias CARoot -rfc"

  echo
  echo "Now the trust store will be generated from the certificate."
  echo

  keytool -keystore $TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME \
    -alias CARoot -import -file $TRUSTSTORE_WORKING_DIRECTORY/$CA_CERT_FILE \
    -noprompt -dname "C=$COUNTRY, ST=$STATE, L=$LOCATION, O=$OU, CN=$CN" -keypass $TRUSTSTORE_PASS -storepass $TRUSTSTORE_PASS
    # -keyalg RSA -sigalg SHA256withRSA -keysize 2048 \

  trust_store_file="$TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME"

  echo
  echo "$TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME was created."

  # don't need the cert because it's in the trust store.
  rm $TRUSTSTORE_WORKING_DIRECTORY/$CA_CERT_FILE

  echo
  echo "Convert truststore to caroot pem format"
  keytool -importkeystore -srckeystore $TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME -destkeystore $TRUSTSTORE_WORKING_DIRECTORY/caroot.p12 -deststoretype PKCS12 -srcstorepass $TRUSTSTORE_PASS -deststorepass $TRUSTSTORE_PASS
  openssl pkcs12 -in $TRUSTSTORE_WORKING_DIRECTORY/caroot.p12 -nokeys -password pass:$TRUSTSTORE_PASS -out $TRUSTSTORE_WORKING_DIRECTORY/CARoot.pem

  rm $TRUSTSTORE_WORKING_DIRECTORY/caroot.p12
else

  trust_store_file=""
  trust_store_private_key_file=""

  echo
  echo -n "Do you use default path for trust store? [yn] "
  read -e use_default_trust_store_path

  if [ "$use_default_trust_store_path" == "y" ]; then
    trust_store_file="$TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME"
    trust_store_private_key_file="$TRUSTSTORE_WORKING_DIRECTORY/ca-key"
  else
    echo -n "Enter the path of the trust store file. "
    read -e trust_store_file

    if ! [ -f $trust_store_file ]; then
      echo "$trust_store_file isn't a file. Exiting."
      exit 1
    fi

    echo -n "Enter the path of the trust store's private key. "
    read -e trust_store_private_key_file

    if ! [ -f $trust_store_private_key_file ]; then
      echo "$trust_store_private_key_file isn't a file. Exiting."
      exit 1
    fi
  fi
fi







# echo "Welcome to the Kafka SSL keystore and trust store generator script."

# trust_store_file=""
# trust_store_private_key_file=""

#   if [ -e "$TRUSTSTORE_WORKING_DIRECTORY" ]; then
#     file_exists_and_exit $TRUSTSTORE_WORKING_DIRECTORY
#   fi

#   mkdir $TRUSTSTORE_WORKING_DIRECTORY
#   echo
#   echo "OK, we'll generate a trust store and associated private key."
#   echo
#   echo "First, the private key."
#   echo

#   openssl req -new -x509 -keyout $TRUSTSTORE_WORKING_DIRECTORY/ca-key \
#     -out $TRUSTSTORE_WORKING_DIRECTORY/ca-cert -days $VALIDITY_IN_DAYS -nodes \
#     -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$OU/CN=$CN"

#   trust_store_private_key_file="$TRUSTSTORE_WORKING_DIRECTORY/ca-key"

#   echo
#   echo "Two files were created:"
#   echo " - $TRUSTSTORE_WORKING_DIRECTORY/ca-key -- the private key used later to"
#   echo "   sign certificates"
#   echo " - $TRUSTSTORE_WORKING_DIRECTORY/ca-cert -- the certificate that will be"
#   echo "   stored in the trust store in a moment and serve as the certificate"
#   echo "   authority (CA). Once this certificate has been stored in the trust"
#   echo "   store, it will be deleted. It can be retrieved from the trust store via:"
#   echo "   $ keytool -keystore <trust-store-file> -export -alias CARoot -rfc"

#   echo
#   echo "Now the trust store will be generated from the certificate."
#   echo

#   keytool -keystore $TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME \
#     -alias CARoot -import -file $TRUSTSTORE_WORKING_DIRECTORY/ca-cert \
#     -noprompt -dname "C=$COUNTRY, ST=$STATE, L=$LOCATION, O=$OU, CN=$CN" -keypass $TRUSTSTORE_PASS -storepass $TRUSTSTORE_PASS

#   trust_store_file="$TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME"

#   echo
#   echo "$TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME was created."

#   # don't need the cert because it's in the trust store.
#   rm $TRUSTSTORE_WORKING_DIRECTORY/$CA_CERT_FILE









echo
echo "Continuing with:"
echo " - trust store file:        $trust_store_file"
echo " - trust store private key: $trust_store_private_key_file"

mkdir -p $KEYSTORE_WORKING_DIRECTORY

echo
echo "Now, a keystore will be generated. Each broker and logical client needs its own"
echo "keystore. This script will create only one keystore. Run this script multiple"
echo "times for multiple keystores."
echo
echo "     NOTE: currently in Kafka, the Common Name (CN) does not need to be the FQDN of"
echo "           this host. However, at some point, this may change. As such, make the CN"
echo "           the FQDN. Some operating systems call the CN prompt 'first / last name'"

# To learn more about CNs and FQDNs, read:
# https://docs.oracle.com/javase/7/docs/api/javax/net/ssl/X509ExtendedTrustManager.html

keytool -keystore $KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME \
  -alias localhost -validity $VALIDITY_IN_DAYS -genkey \
   -noprompt -dname "C=$COUNTRY, ST=$STATE, L=$LOCATION, O=$OU, CN=$CN" -keypass $KEYSTORE_PASS -storepass $KEYSTORE_PASS
  # -keyalg RSA -sigalg SHA256withRSA -keysize 2048 \

echo
echo "'$KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME' now contains a key pair and a"
echo "self-signed certificate. Again, this keystore can only be used for one broker or"
echo "one logical client. Other brokers or clients need to generate their own keystores."

echo
echo "Fetching the certificate from the trust store and storing in $CA_CERT_FILE."
echo

keytool -keystore $trust_store_file -export -alias CARoot -rfc -file $CA_CERT_FILE -keypass $TRUSTSTORE_PASS -storepass $TRUSTSTORE_PASS

echo
echo "Now a certificate signing request will be made to the keystore."
echo
keytool -keystore $KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME -alias localhost \
  -certreq -file $KEYSTORE_SIGN_REQUEST -keypass $KEYSTORE_PASS -storepass $KEYSTORE_PASS

echo
echo "Now the trust store's private key (CA) will sign the keystore's certificate."
echo
openssl x509 -sha256 -req -CA $CA_CERT_FILE -CAkey $trust_store_private_key_file \
  -in $KEYSTORE_SIGN_REQUEST -out $KEYSTORE_SIGNED_CERT \
  -days $VALIDITY_IN_DAYS -CAcreateserial
# creates $KEYSTORE_SIGN_REQUEST_SRL which is never used or needed.

echo
echo "Now the CA will be imported into the keystore."
echo
keytool -keystore $KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME -alias CARoot \
  -import -file $CA_CERT_FILE -keypass $KEYSTORE_PASS -storepass $KEYSTORE_PASS -noprompt
rm $CA_CERT_FILE # delete the trust store cert because it's stored in the trust store.

echo
echo "Now the keystore's signed certificate will be imported back into the keystore."
echo
keytool -keystore $KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME -alias localhost -import \
  -file $KEYSTORE_SIGNED_CERT -keypass $KEYSTORE_PASS -storepass $KEYSTORE_PASS

echo
echo "All done!"
echo
echo "Deleting intermediate files. They are:"
echo " - '$KEYSTORE_SIGN_REQUEST_SRL': CA serial number"
echo " - '$KEYSTORE_SIGN_REQUEST': the keystore's certificate signing request"
echo "   (that was fulfilled)"
echo " - '$KEYSTORE_SIGNED_CERT': the keystore's certificate, signed by the CA, and stored back"
echo "    into the keystore"

  rm $KEYSTORE_SIGN_REQUEST_SRL
  rm $KEYSTORE_SIGN_REQUEST
  rm $KEYSTORE_SIGNED_CERT


echo 
echo "Convert cert and key to pem"
keytool -exportcert -alias localhost -keystore $KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME -storepass $KEYSTORE_PASS -rfc -file $KEYSTORE_WORKING_DIRECTORY/cert.pem

keytool -v -importkeystore -srckeystore $KEYSTORE_WORKING_DIRECTORY/$KEYSTORE_FILENAME -srcalias localhost -destkeystore $KEYSTORE_WORKING_DIRECTORY/cert_and_key.p12 -deststoretype PKCS12 -srcstorepass $KEYSTORE_PASS -deststorepass $KEYSTORE_PASS
openssl pkcs12 -in $KEYSTORE_WORKING_DIRECTORY/cert_and_key.p12 -password pass:$KEYSTORE_PASS -nocerts -nodes -out $KEYSTORE_WORKING_DIRECTORY/key.pem
rm $KEYSTORE_WORKING_DIRECTORY/cert_and_key.p12 