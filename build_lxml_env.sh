# To be sourced, not sh'ed

# Builds lxml and its dependences on a GCP Debian VM,
# and opens an interactive Python session where you can use lxml in-place

sudo apt install autoconf build-essential gcc git libtool pkg-config python3-dev python3-venv -y
cd $HOME
git clone https://gitlab.gnome.org/GNOME/libxml2.git
cd $HOME/libxml2/
./autogen.sh
make
sudo make install
cd $HOME
git clone https://gitlab.gnome.org/GNOME/libxslt.git
cd $HOME/libxslt/
./autogen.sh
make
sudo make install
cd $HOME
python3 -m venv venv
source venv/bin/activate
git clone https://github.com/lxml/lxml.git
cd $HOME/lxml/
pip3 install -r requirements.txt
python3 setup.py build_ext -i --with-cython --with-xml2-config=$HOME/libxml2/xml2-config --with-xslt-config=$HOME/libxslt/xslt-config

alias lxmlpython='PYTHONPATH=$HOME/lxml/src LD_LIBRARY_PATH=/usr/local/lib python3'

# TODO add aliases for pushing and pulling Git patches