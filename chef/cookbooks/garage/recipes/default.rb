%w(emacs vim zsh htop).each do |i|
  package i
end

bash "Set vagrant's shell to zsh" do
  code <<-EOT
    chsh -s /bin/zsh vagrant
  EOT
  not_if 'test "/bin/zsh" = "$(grep vagrant /etc/passwd | cut -d: -f7)"'
end

bash "install cask" do
  environment ({ 'HOME' => ::Dir.home('vagrant'), 'USER' => 'vagrant' })
  code <<-EOT
     su - vagrant
     curl -fsSL https://raw.githubusercontent.com/cask/cask/master/go | python
  EOT
  not_if 'test -e /home/vagrant/.cask'
end

bash "install docker" do
  code <<-EOT
    curl -fsSL get.docker.com | sudo sh -
  EOT
  not_if 'test -e /usr/bin/docker'
end

template '/home/vagrant/.zshrc' do
  owner 'vagrant'
  group 'vagrant'
  mode '0644'
end

template '/home/vagrant/.gitconfig' do
  owner 'vagrant'
  group 'vagrant'
  mode '0644'
end

directory '/home/vagrant/.emacs.d' do
  owner 'vagrant'
  group 'vagrant'
  mode '0755'
  action :create
end

template '/home/vagrant/.emacs.d/init.el' do
  owner 'vagrant'
  group 'vagrant'
  mode '0644'
end

template '/home/vagrant/.emacs.d/Cask' do
  owner 'vagrant'
  group 'vagrant'
  mode '0644'
end

bash "cask install" do
  environment ({ 'HOME' => ::Dir.home('vagrant'), 'USER' => 'vagrant' })
  code <<-EOT
     su - vagrant
     cd $HOME/.emacs.d
     ~/.cask//bin/cask install
  EOT
end

git '/home/vagrant/.anyenv' do
  user 'vagrant'
  repository 'https://github.com/riywo/anyenv'
  revision 'master'
  action :sync
  notifies :run, 'script[goenv-setup]', :immediately
end

script "goenv-setup" do
  environment ({ 'HOME' => ::Dir.home('vagrant'), 'USER' => 'vagrant' })
  user 'vagrant'
  interpreter "zsh"
  code <<-EOT
    source ~/.zshrc
    anyenv install goenv
    source ~/.zshrc
    goenv install 1.9.1
    goenv global 1.9.1
  EOT
  action :nothing
  notifies :run, 'script[golang-setup]', :immediately
end

script "golang-setup" do
  environment ({ 'HOME' => ::Dir.home('vagrant'), 'USER' => 'vagrant' })
  user 'vagrant'
  interpreter "zsh"
  code <<-EOT
    source ~/.zshrc
    mkdir -p ~/local/bin
    go get -u github.com/nsf/gocode
    go get -u github.com/rogpeppe/godef
    go get -u golang.org/x/tools/cmd/guru
    go get -u golang.org/x/tools/cmd/gorename
    go get -u golang.org/x/tools/cmd/goimports
    go get -u github.com/alecthomas/gometalinter
    gometalinter --install --update
    go get -u github.com/motemen/ghq
    curl -s -L https://github.com/peco/peco/releases/download/v0.5.1/peco_linux_amd64.tar.gz|tar zxvf - && mv -f peco_linux_amd64/peco ~/local/bin && rm -rf ./peco_linux_amd64
  EOT
  action :nothing
end

