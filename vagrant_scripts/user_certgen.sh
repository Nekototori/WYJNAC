openssl genrsa -out $(hostname)some_user.key 2048

openssl req -new \
  -key $(hostname)some_user.key \
  -out /vagrant/$(hostname)some_user.csr \
  -subj "/CN=some_user/O=nginx-app"
