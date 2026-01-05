openssl genrsa -out /vagrant/$(hostname)some_user.key 2048

openssl req -new \
  -key /vagrant/$(hostname)some_user.key \
  -out /vagrant/$(hostname)some_user.csr \
  -subj "/CN=bob/O=userspace"

cat /vagrant/$(hostname)some_user.csr | base64 | tr -d '\n' > /vagrant/$(hostname)base64.txt