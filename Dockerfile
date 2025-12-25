FROM ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install base utils
RUN apt-get update && apt-get install -y \
    wget curl gnupg software-properties-common lsb-release unzip \
    build-essential bc sudo tzdata locales screen dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Java 8
RUN apt-get update && apt-get install -y openjdk-8-jdk
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Maven 3.6.3
RUN wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.zip \
    && unzip apache-maven-3.6.3-bin.zip -d /opt/ \
    && ln -sf /opt/apache-maven-3.6.3/bin/mvn /usr/bin/mvn \
    && rm apache-maven-3.6.3-bin.zip
RUN mvn -version

# Postgres 9.6
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo "deb http://apt-archive.postgresql.org/pub/repos/apt/ bionic-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid
RUN apt-get update && apt-get install -y postgresql-9.6 postgresql-client-9.6 postgresql-contrib-9.6

# Miniconda2
ENV CONDA_DIR=/opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda2-latest-Linux-x86_64.sh -O /tmp/miniconda.sh \
    && /bin/bash /tmp/miniconda.sh -b -p $CONDA_DIR \
    && rm /tmp/miniconda.sh
ENV PATH=$CONDA_DIR/bin:$PATH

# Copy source
WORKDIR /app
COPY . /app


RUN find /app -type f -name "*.sh" -exec dos2unix {} \; \
    && find /app -type f -name "*.py" -exec dos2unix {} \;


RUN conda env create -f /app/Experiments/environment.yml
ENV PATH=/opt/conda/envs/anyk_env/bin:$PATH


SHELL ["/bin/bash", "-c"]


RUN source activate anyk_env && python --version


RUN mvn package


RUN cd /app/Experiments/VLDB21/TPCH/inputs && chmod +x dbgen

ENTRYPOINT ["/bin/bash", "/app/Experiments/VLDB21/start_container.sh"]
