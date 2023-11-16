FROM neurodebian:buster
RUN apt-get update -qq \
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

#Install fsl.
#Code adapted from: https://git.fmrib.ox.ac.uk/thanayik/fsl-docker-example-bet/-/blob/main/Dockerfile?ref_type=heads

#Install Anaconda so we can get the correct fsl 
ENV CONDA_DIR="/opt/miniconda-latest" \
    PATH="/opt/miniconda-latest/bin:$PATH" \
    FSL_CONDA_CHANNEL="https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/public"


RUN echo "Installing Ancaonda" \
    && export PATH="/opt/miniconda-latest/bin:$PATH" \
    && echo "Downloading Miniconda installer ..." \
    && conda_installer="/tmp/miniconda.sh" \
    && curl -fsSL -o "$conda_installer" https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash "$conda_installer" -b -p /opt/miniconda-latest \
    && rm -f "$conda_installer" \
    && conda update -yq -nbase conda \
    # Prefer packages in conda-forge
    && conda config --system --prepend channels conda-forge \
    # Packages in lower-priority channels not considered if a package with the same
    # name exists in a higher priority channel. Can dramatically speed up installations.
    # Conda recommends this as a default
    # https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-channels.html
    && conda config --set channel_priority strict \
    && conda config --system --set auto_update_conda false \
    && conda config --system --set show_channel_urls true \
    # Enable `conda activate`
    && conda init bash \ 
    && conda install --name base -c conda-forge tini \
    && conda install --name base -c $FSL_CONDA_CHANNEL fsl-bet2 -c conda-forge

ENV FSLDIR="/opt/conda"

#Set mount point default
ENV DATAMOUNT /usr/data
RUN mkdir /usr/data

#Make the entrypoint executable.
#Add local files.
COPY . /app/
WORKDIR /app
RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
