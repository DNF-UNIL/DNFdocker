ARG BASE_CONTAINER=ubuntu:bionic-20190612@sha256:9b1702dcfe32c873a770a32cfd306dd7fc1c4fd134adfb783db68defc8894b3c
FROM $BASE_CONTAINER


LABEL maintainer="Carlos Vivar <carlos.vivarrios@unil.ch>"
ARG NB_USER="DNF"
ARG NB_UID="1000"
ARG NB_GID="100"

USER root

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    run-one \
 && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=$NB_USER \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER
    
# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=$NB_USER \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

# Add a script that we will use to correct permissions after running certain commands
ADD fix-permissions /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc

# Create NB_USER wtih name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd && \
    fix-permissions $HOME && \
    fix-permissions "$(dirname $CONDA_DIR)"

USER $NB_UID
WORKDIR $HOME

# Setup work directory for backward-compatibility
RUN mkdir /home/$NB_USER/work && \
    fix-permissions /home/$NB_USER

# Install conda as jovyan and check the md5 sum provided on the download site
ENV MINICONDA_VERSION=4.6.14 \
    CONDA_VERSION=4.7.10

RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "718259965f234088d785cad1fbd7de03 *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "conda ${CONDA_VERSION}" >> $CONDA_DIR/conda-meta/pinned && \
    $CONDA_DIR/bin/conda config --system --prepend channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA_DIR/bin/conda config --system --set show_channel_urls true && \
    $CONDA_DIR/bin/conda install --quiet --yes conda && \
    $CONDA_DIR/bin/conda update --all --quiet --yes && \
    conda list python | grep '^python ' | tr -s ' ' | cut -d '.' -f 1,2 | sed 's/$/.*/' >> $CONDA_DIR/conda-meta/pinned && \
    conda clean --all -f -y && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install Tini
RUN conda install --quiet --yes 'tini=0.18.0' && \
    conda list tini | grep tini | tr -s ' ' | cut -d ' ' -f 1,2 >> $CONDA_DIR/conda-meta/pinned && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install Jupyter Notebook, Lab, and Hub
# Generate a notebook server config
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
RUN conda install --quiet --yes \
    'notebook=6.0.0' \
    'jupyterhub=1.0.0' \
    'jupyterlab=1.1.3' && \
    conda clean --all -f -y && \
    npm cache clean --force && \
    jupyter notebook --generate-config && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# ##############################
# Install general tools
# ##################################
RUN apt-get update && apt-get install -y  --no-install-recommends \
    git \
    make \
    curl \
    bzip2 \
    g++ \
    libz-dev \
    wget \
    libncurses-dev \
    unzip \
    ftp \
    vim \
    htop \
    fonts-dejavu \
    unixodbc \
    unixodbc-dev \
    r-cran-rodbc \
    gfortran \
    gcc && \
    rm -rf /var/lib/apt/lists/*

    
  
    
########################################## IMAGE ANALYSIS ####################################################

    
    
########################################## BIOINFORMATICS ####################################################
#-#-#-#-#-#-#-#-#-#-#-#-#
# R 
#-#-#-#-#-#-#-#-#-#-#-#-#

USER $NB_UID

# R packages
RUN conda install --quiet --yes \
    'r-base=3.6.1' \
    'r-caret=6.0*' \
    'r-crayon=1.3*' \
    'r-devtools=2.0*' \
    'r-forecast=8.7*' \
    'r-hexbin=1.27*' \
    'r-htmltools=0.3*' \
    'r-htmlwidgets=1.3*' \
    'r-irkernel=1.0*' \
    'r-nycflights13=1.0*' \
    'r-plyr=1.8*' \
    'r-randomforest=4.6*' \
    'r-rcurl=1.95*' \
    'r-reshape2=1.4*' \
    'r-rmarkdown=1.14*' \
    'r-rodbc=1.3*' \
    'r-rsqlite=2.1*' \
    'r-shiny=1.3*' \
    'r-sparklyr=1.0*' \
    'r-tidyverse=1.2*' \
    'unixodbc=2.3.*' \
    && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR

# Install e1071 R package (dependency of the caret R package)
RUN conda install --quiet --yes r-e1071

    
#-#-#-#-#-#-#-#-#-#-#-#-#
# BAM processing tools
#-#-#-#-#-#-#-#-#-#-#-#-#
RUN curl -kL https://github.com/samtools/htslib/releases/download/1.3.2/htslib-1.3.2.tar.bz2 | tar -C /tmp -jxf - && \
    cd /tmp/htslib-1.3.2 && make && make install && \
    rm -rf /tmp/htslib-1.3.2
RUN curl -kL https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2 | tar -C /tmp -jxf - && \
    cd /tmp/samtools-1.3.1 && make && make install && \
    rm -rf /tmp/samtools-1.3.1
RUN curl -kL https://github.com/samtools/bcftools/releases/download/1.3.1/bcftools-1.3.1.tar.bz2 | tar -C /tmp -jxf - && \
    cd /tmp/bcftools-1.3.1 && make && make install && \
    rm -rf /tmp/bcftools-1.3.1
    
#-#-#-#-#-#-#-#-#-#-#-#-#
# DNA analysis tools
#-#-#-#-#-#-#-#-#-#-#-#-#
#bwa
RUN curl -kL http://netix.dl.sourceforge.net/project/bio-bwa/bwa-0.7.15.tar.bz2 | tar -C /tmp -jxf - && \
    cd /tmp/bwa-0.7.15 && make && find /tmp/bwa-0.7.15/ -type f -executable -exec mv '{}' /usr/local/bin/ ';' && \
    rm -rf /tmp/bwa-0.7.15/
    
    
#-#-#-#-#-#-#-#-#-#-#-#-#
# RNA analysis tools 
#-#-#-#-#-#-#-#-#-#-#-#-#
#STAR
RUN curl -kL https://github.com/alexdobin/STAR/archive/2.5.2b.tar.gz | tar -C /tmp -zxf - && \ 
    mv /tmp/STAR-2.5.2b/bin/Linux_x86_64_static/* /usr/local/bin/ && \
    rm -rf /tmp/STAR-2.5.2b/

#bowtie2 + tophat + cufflinks
RUN curl -kL http://netix.dl.sourceforge.net/project/bowtie-bio/bowtie2/2.2.9/bowtie2-2.2.9-linux-x86_64.zip -o /tmp/bowtie2-2.2.9-linux-x86_64.zip && \
    unzip /tmp/bowtie2-2.2.9-linux-x86_64.zip -d /tmp && \
    find /tmp/bowtie2-2.2.9/ -maxdepth 1 -type f -executable -exec mv '{}' /usr/local/bin/ ';' && \
    rm -rf /tmp/bowtie2-2.2.9-linux-x86_64.zip /tmp/bowtie2-2.2.9
RUN curl -kL https://ccb.jhu.edu/software/tophat/downloads/tophat-2.1.1.Linux_x86_64.tar.gz | tar -C /tmp -zxf - && \
    find /tmp/tophat-2.1.1.Linux_x86_64/ -maxdepth 1 -executable -type f -exec mv '{}' /usr/local/bin/ ';' && \
    rm -rf /tmp/tophat-2.1.1.Linux_x86_64
RUN curl -kL http://cole-trapnell-lab.github.io/cufflinks/assets/downloads/cufflinks-2.2.1.Linux_x86_64.tar.gz | tar -C /tmp -zxf - && \
    find /tmp/cufflinks-2.2.1.Linux_x86_64/ -maxdepth 1 -executable -type f -exec mv '{}' /usr/local/bin/ ';' && \
    rm -rf /tmp/cufflinks-2.2.1.Linux_x86_64   
    
    
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
# Other tools to install
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

# SRA toolkit
RUN curl -kL http://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/2.7.0/sratoolkit.2.7.0-ubuntu64.tar.gz | tar -C /tmp -zxf - 


#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
# Install HTSeq-count, MACS2, HTSeq, umi_tools
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
RUN apt-get update && apt-get install -y \
    build-essential \
    python3.7-dev \
    python-numpy \
    python-matplotlib \
    python-pip \
    libbz2-dev \
    liblzma-dev

RUN pip install --upgrade pip && easy_install -U setuptools
RUN pip install pysam MACS2 HTSeq
RUN pip install cython pandas future umi_tools


#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
# Cutadapt & Fastx toolkit
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
RUN pip install --upgrade cutadapt
RUN apt-get update && apt-get install -y fastx-toolkit


VOLUME ["/docker_dnf/"]
ENTRYPOINT ["/bin/bash"]


EXPOSE 8888

# Configure container startup
#ENTRYPOINT ["tini", "-g", "--"]
#CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/

# Fix permissions on /etc/jupyter as root
USER root
RUN fix-permissions /etc/jupyter/

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID


#EXPOSE :80
