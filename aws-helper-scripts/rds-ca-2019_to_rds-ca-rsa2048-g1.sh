#!/bin/bash
# Important
# When you schedule this operation, make sure that you have updated your client-side trust store beforehand.
# Use --apply-immediately to apply the update immediately. By default, this operation is scheduled to run during your next maintenance window.
# Reference: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html

# Fetch the list of RDS databases
output=$(aws rds describe-db-instances --output json)

# Extract the database names using jq
database_names=$(echo "$output" | jq -r '.DBInstances[] | select(.DBInstanceIdentifier) | .DBInstanceIdentifier')

# Display the non-null database names
for name in $database_names; do
    if [ "$name" != "null" ]; then
        #echo "$name"
        #Get database current CA
        CACertificateIdentifier=$(echo "$output" | jq -r '.DBInstances[0].CACertificateIdentifier')
        #echo $CACertificateIdentifier
        # Check if the CA is rds-ca-2019 and change it to the current ca or required ca
        # Options: rds-ca-rsa2048-g1, rds-ca-rsa4096-g1 or rds-ca-ecc384-g1
        # Check if the CACertificateIdentifier contains "rds-ca-2019"
        if [[ "$CACertificateIdentifier" == *"rds-ca-2019"* ]]; then
            #echo "CACertificateIdentifier contains 'rds-ca-2019'."
            # #For Linux, macOS, or Unix:
            aws rds modify-db-instance --db-instance-identifier $name --ca-certificate-identifier rds-ca-rsa2048-g1 --apply-immediately > /dev/null 2>&1 &
            # Check if the command was successful or not
            if [ $? -eq 0 ]; then
                echo "DB instance $name updated to use the new CA certificate"
            else
                echo "CA Update for $name failed."
            fi
        else
            echo "$name is not using old CA certificat."
        fi
    fi
done
