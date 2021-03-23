#!/usr/bin/env bash
set -Eeuo pipefail

printf "\nUninstall Agent"
cd /home/testadmin/azagent
# intentionally allow both things to fail
sudo ./svc.sh uninstall || true
printf "cd /home/testadmin/azagent && ./config.sh remove --unattended --auth pat --token $PAT_TOKEN" > ./wrap.sh
sudo chmod a+x ./wrap.sh
runuser -l testadmin -c '/home/testadmin/azagent/wrap.sh'

printf "\nFinished successfully"
