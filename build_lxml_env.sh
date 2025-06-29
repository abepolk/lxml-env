BUCKET_NAME=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/bucket_name -H "Metadata-Flavor: Google")

# TODO make the following comment possible for a startup script
# To be sourced, not sh'ed

# Build lxml and its dependences
apt install -y autoconf build-essential gcc git libtool pkg-config python3-dev python3-venv -y
cd /
git clone https://gitlab.gnome.org/GNOME/libxml2.git
cd /libxml2/
./autogen.sh
make
make install
cd /
git clone https://gitlab.gnome.org/GNOME/libxslt.git
cd /libxslt/
./autogen.sh
make
make install
cd /
python3 -m venv venv
source venv/bin/activate
git clone https://github.com/lxml/lxml.git
cd /lxml/
pip3 install -r requirements.txt
python3 setup.py build_ext -i --with-cython --with-xml2-config=/libxml2/xml2-config --with-xslt-config=/libxslt/xslt-config
# Deactivate if this is sh'ed and if that means that we can't keep it active anyway.

# Possibly leave some marker, like VM metadata, to say if this script has already run on the instance. I could put this at the
# start or end of this script.

alias lxmlpython='PYTHONPATH=/lxml/src LD_LIBRARY_PATH=/usr/local/lib python3'

pushpatch () {
    git diff | gsutil cp - gs://$BUCKET_NAME/$1
}

pullpatch () {
    gsutil cp gs://$BUCKET_NAME/$1 - | git apply -
}