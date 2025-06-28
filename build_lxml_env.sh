BUCKET_NAME=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/bucket_name -H "Metadata-Flavor: Google")

# TODO make the following comment possible for a startup script
# To be sourced, not sh'ed

# Build lxml and its dependences
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
# Deactivate if this is sh'ed and if that means that we can't keep it active anyway.

# Possibly leave some marker, like VM metadata, to say if this script has already run on the instance. I could put this at the
# start or end of this script.

alias lxmlpython='PYTHONPATH=$HOME/lxml/src LD_LIBRARY_PATH=/usr/local/lib python3'

pushpatch () {
    git diff | gsutil cp - gs://$BUCKET_NAME/$1
}

pullpatch () {
    gsutil cp gs://$BUCKET_NAME/$1 - | git apply -
}