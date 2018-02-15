 #!/bin/bash
set -e

#expecting 2 parameters. First the uaa api endpoint, 2nd the uaa admin credential, and 3rd the exporter password
addExporterUaaUsers(){
    uaac target $1 --skip-ssl-validation
    uaac token client get admin -s $2
    uaac client add firehose_exporter \
        --name prometheus-firehose \
        --secret $3 \
        --authorized_grant_types client_credentials,refresh_token \
        --authorities doppler.firehose

    uaac client add cf_exporter \
        --name cf_exporter \
        --secret $3 \
        --authorized_grant_types client_credentials,refresh_token \
        --authorities cloud_controller.global_auditor
}

#expecting a single string input parameter
validateStringInput(){
    if [ -z $1 ]; then
        echo "Invalid parameter entered" >&2; exit 1
    fi
}

#expecting a single integer input parameter
validateIntegerInput(){
    re='^[0-9]+$'
    if ! [[ $1 =~ $re ]] ; then
        echo "Invalid parameter entered: Not a number" >&2; exit 1
    fi
}

echo -n "The number of environment(s) to configure [ENTER]: "
read envNum
validateIntegerInput $envNum

for (( c=1; c<=$envNum; c++ )) do
    echo -n "Enter UAA endpoint url (https://uaa.sys.example.com): [ENTER]: "
    read uaaUrl
    validateStringInput $uaaUrl

    echo -n "Enter uaa admin credential for the environment [ENTER]: "
    read adminCred
    validateStringInput $adminCred

    echo -n "Enter exporter password [ENTER]: "
    read exporterPassword
    validateStringInput $exporterPassword
    
    addExporterUaaUsers $uaaUrl $adminCred $exporterPassword
    
done

