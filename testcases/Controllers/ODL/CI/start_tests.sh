#!/bin/bash
# Script requires that test environment is created already
# it includes python2.7 virtual env with robot packages and git

# Colors
green='\033[0;32m'
light_green='\033[1;32m'
nc='\033[0m' # No Color

usage="Script for starting ODL tests. Tests to be executed are specified in test_list.txt file.

usage:
[var=value] bash $(basename "$0") [-h]

where:
    -h     show this help text
    var    one of the following: OSTACK_IP, ODL_PORT, USER, PASS, PATH_TO_VENV
    value  new value for var

example:
    OSTACK_IP=oscontro1 ODL_PORT=8080 bash $(basename "$0")"

while getopts ':h' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done

echo -e "${green}Current environment parameters for ODL suite.${nc}"
# Following vars might be also specified as CLI params
set -x
PATH_TO_VENV=${PATH_TO_VENV:-~/.virtualenvs/robot/bin/activate}
OSTACK_IP=${OSTACK_IP:-'oscontrol'}
ODL_PORT=${ODL_PORT:-8081}
USR_NAME=${USR_NAME:-'admin'}
PASS=${PASS:-'octopus'}
set +x

echo -e "${green}Cloning ODL integration git repo.${nc}"
if [ -d integration ]; then
    cd integration
    git checkout -- .
    git pull
    cd -
else
    git clone https://github.com/opendaylight/integration.git
fi

# Change openstack password for admin tenant in neutron suite
sed -i "s/\"password\": \"admin\"/\"password\": \"${PASS}\"/" integration/test/csit/suites/openstack/neutron/__init__.robot

echo -e "${green}Activate python virtual env.${nc}"
source $PATH_TO_VENV

# List of tests are specified in test_list.txt
# those are relative paths to test directories from integartion suite
echo -e "${green}Executing chosen tests.${nc}"
while read line
do
    # skip comments
    [[ ${line:0:1} == "#" ]] && continue
    # skip empty lines
    [[ -z "${line}" ]] && continue

    echo -e "${light_green}Starting test: $line ${nc}"
    pybot -v OPENSTACK:${OSTACK_IP} -v PORT:${ODL_PORT} -v CONTROLLER:${OSTACK_IP} $line
done < test_list.txt

echo -e "${green}Deactivate venv.${nc}"
deactivate

# Now we can copy output.xml, log.html and report.xml files generated by robot.
