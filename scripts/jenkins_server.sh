#!/bin/bash

set -x

function wait_for_jenkins()
{
  while (( 1 )); do
      echo "waiting for Jenkins to launch on port [8080] ..."
      
      netcat -zv 127.0.0.1 8080
      if (( $? == 0 )); then
          break
      fi

      sleep 3
  done

  echo "Jenkins launched"
}

function updating_jenkins_master_password ()
{

  cat > ./jenkinsHash.py <<EOF
import bcrypt
import sys

if not sys.argv[1]:
  sys.exit(10)

plaintext_pwd=sys.argv[1]
encrypted_pwd=bcrypt.hashpw(plaintext_pwd.encode('utf8'), bcrypt.gensalt(rounds=10, prefix=b"2a"))
isCorrect=bcrypt.checkpw(plaintext_pwd.encode('utf8'), encrypted_pwd)

if not isCorrect:
  sys.exit(20);

print(encrypted_pwd.decode('ascii'))
EOF
   
  chmod +x ./jenkinsHash.py
  
  # Wait till /var/lib/jenkins/users/admin* folder gets created
  sleep 3
  
  #cd /var/lib/jenkins/users/admin*
  pwd
  while (( 1 )); do
      echo "Waiting for Jenkins to generate admin user's config file ..."
      sudo find  /var/lib/jenkins/users/admin_* | grep config.xml
      if [[ $? -eq 0 ]]; then
          break
      fi

      sleep 3
  done

  echo "Admin config file created"

  admin_password=$(python3 ./jenkinsHash.py password 2>&1)
  echo $admin_password
  
  sudo -s chmod -R  777 /var/lib/jenkins/users/admin*
  cd /var/lib/jenkins/users/admin*
  # Please do not remove alter quote as it keeps the hash syntax intact or else while substitution, $<character> will be replaced by null
  xmlstarlet -q ed --inplace -u "/user/properties/hudson.security.HudsonPrivateSecurityRealm_-Details/passwordHash" -v '#jbcrypt:'"$admin_password" config.xml

  # Restart
  sudo systemctl restart jenkins.service
  sleep 3

}

function install_packages ()
{

  wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key |sudo gpg --dearmor -o /usr/share/keyrings/jenkins.gpg
  sudo sh -c 'echo deb [signed-by=/usr/share/keyrings/jenkins.gpg] http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
  sudo apt update
  sudo apt install -y jenkins
  sudo systemctl enable jenkins.service
  sudo systemctl restart jenkins.service
  sleep 3
}

function configure_jenkins_server ()
{
  # Jenkins cli
  echo "installing the Jenkins cli ..."
  sudo cp /var/cache/jenkins/war/WEB-INF/lib/cli-2.375.1.jar /var/lib/jenkins/jenkins-cli.jar

  # Getting initial password
  # PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
  PASSWORD="password"
  sleep 10

  jenkins_dir="/var/lib/jenkins"
  plugins_dir="$jenkins_dir/plugins"

  sudo cd $jenkins_dir

  # Open JNLP port
  xmlstarlet -q ed --inplace -u "/hudson/slaveAgentPort" -v 33453 config.xml

  cd $plugins_dir || { echo "unable to chdir to [$plugins_dir]"; exit 1; }

  # List of plugins that are needed to be installed 
  plugin_list="git-client git github-api github-oauth github MSBuild ssh-slaves workflow-aggregator ws-cleanup"

  # remove existing plugins, if any ...
  rm -rfv $plugin_list

  for plugin in $plugin_list; do
      echo "installing plugin [$plugin] ..."
      java -jar $jenkins_dir/jenkins-cli.jar -s http://127.0.0.1:8080/ -auth admin:$PASSWORD install-plugin $plugin
  done

  # Restart jenkins after installing plugins
  java -jar $jenkins_dir/jenkins-cli.jar -s http://127.0.0.1:8080 -auth admin:$PASSWORD safe-restart
}

### script starts here ###

install_packages

wait_for_jenkins

updating_jenkins_master_password

wait_for_jenkins

configure_jenkins_server

echo "Done"
exit 0
