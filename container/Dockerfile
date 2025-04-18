FROM neurodebian:buster
RUN apt-get update -qq \
    && apt-get install -y software-properties-common \
    && add-apt-repository "deb http://neuro.debian.net/debian buster main contrib non-free" \
    && apt-get update \
    && apt-get install -y -q --no-install-recommends \
           ca-certificates \
           curl \
           unzip \
           build-essential \ 
           zlib1g-dev \
           libncurses5-dev \
           libgdbm-dev \
           libnss3-dev \
           libssl-dev \
           libreadline-dev \
           libffi-dev \
           libsqlite3-dev \
           libbz2-dev \
           fsl=5.0.9-5~nd100+1 \
    && rm -rf /var/lib/apt/lists/* \

#Install Python
#Download.
RUN mkdir tmp
WORKDIR /tmp
RUN echo "Downloading and Extracting Python 3.11.6" \
    && curl -fsSL -o Python-3.11.6.tar.xz https://www.python.org/ftp/python/3.11.6/Python-3.11.6.tar.xz \
    && tar -xf Python-3.11.6.tar.xz \
    && rm Python-3.11.6.tar.xz \
    && useradd -m nonroot \
    && chown -R nonroot /tmp/Python-3.11.6

WORKDIR /tmp/Python-3.11.6
RUN echo "Installing Python 3.11.6" \
    && chmod +x configure \
    && ./configure --enable-optimizations --build=x86_64-unknown-linux-gnu --prefix=/usr/local \
    && make install \
    && make clean 

#Install packages with pip
RUN echo "Installing Python Packages" \
    && python3 -m pip install --no-cache-dir  \
         "scikit-learn==1.3.2" \
         "pandas==2.1.2" \
         "pillow==10.1.0" \
         "datalad" \
         "nibabel==4.0.0" \
         "tensorflow==2.14.0" \
         "datalad-installer" \
         "h5py==3.8.0" \
         "--force-reinstall" \
    # Clean up
    && rm -rf ~/.cache/pip/*

#Clean up.
RUN echo "Cleaning Up." \
    && rm -rf /tmp/Python-3.11.6

#Set mount point default
ENV DATAMOUNT=/usr/data
RUN mkdir /usr/data

#Make the entrypoint executable.
#Add local files.
COPY . /app/
WORKDIR /app

ENTRYPOINT ["/app/entrypoint.sh"]
