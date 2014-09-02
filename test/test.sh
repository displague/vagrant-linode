# if ! bundle exec vagrant box list | grep linode 1>/dev/null; then
#     bundle exec vagrant box add linode box/linode.box
# fi

cd test

bundle exec vagrant up --provider=linode
bundle exec vagrant up
bundle exec vagrant provision
bundle exec vagrant rebuild
bundle exec vagrant halt
bundle exec vagrant destroy

cd ..
