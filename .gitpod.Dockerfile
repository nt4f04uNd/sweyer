FROM gitpod/workspace-full:latest

# ENVs
ENV ANDROID_HOME=/home/gitpod/android-sdk \
    SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-6200805_latest.zip" \
    ANDROID_VERSION=R \
    ANDROID_BUILD_TOOLS_VERSION=30.0.0-rc1 \
    FLUTTER_HOME=/home/gitpod/flutter

USER root

## Apt-get some tools like dart, java, etc.
RUN curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list && \
    apt-get update && \
    apt-get -y install build-essential dart libkrb5-dev gcc make gradle openjdk-8-jdk && \
    apt-get clean && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*;

USER gitpod

# PATH   
ENV PATH="${FLUTTER_HOME}/bin:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# Flutter SDK
RUN cd /home/gitpod \
    && wget -qO flutter_sdk.tar.xz \
    https://storage.googleapis.com/flutter_infra/releases/dev/linux/flutter_linux_v1.15.3-dev.tar.xz &&\
    tar -xvf flutter_sdk.tar.xz\
    && rm -f flutter_sdk.tar.xz

# Create folder, download SDK archive in it, which then gets unzipped and deleted
RUN mkdir "$ANDROID_HOME" .android \
    && cd "$ANDROID_HOME" \
    && curl -o sdk.zip $SDK_URL \
    && unzip sdk.zip \
    && rm sdk.zip  

# Start android SDK update and setup SDK tools
RUN yes | $ANDROID_HOME/tools/bin/sdkmanager --sdk_root=$ANDROID_HOME --update \
    && yes | $ANDROID_HOME/tools/bin/sdkmanager --sdk_root=$ANDROID_HOME "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
    "platforms;android-${ANDROID_VERSION}" \
    "platform-tools"
