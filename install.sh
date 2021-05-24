#Suppresion des versions existantes de docker
sudo apt-get remove docker docker-engine docker.io containerd runc

#Installation de docker
sudo apt-get update
sudo apt-get install \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg \
     lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

#Installation de docker-compse
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

#Création de l'utilisateur deployer
sudo groupadd docker
sudo adduser deployer
sudo usermod -aG docker deployer
sudo chown deployer srv/
