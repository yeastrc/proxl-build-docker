
#  Docker Image to build proxl-web

#   if existing command not work to build docker image, see https://docs.docker.com/go/buildx/

FROM ubuntu:24.04

# Gradle is downloaded via Gradle Wrapper in Proxl so NO need to add here

RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install \
    wget curl gnupg ca-certificates locales ant unzip

# --- Eclipse Temurin (Adoptium) apt repo ---
#   Provides JDK 25 (build/run Gradle + all Java 25 projects) and JDK 8
#   (for proxl_submit_import, which stays on Java 8).
#   Uses Temurin to match the runtime images (tomcat:11.0-jdk25-temurin-noble
#   and eclipse-temurin:25-jre). temurin-25 is not in Ubuntu's archive and newer
#   Ubuntu releases drop openjdk-8, so one vendor repo serving both versions is
#   the stable choice on 24.04 LTS.
RUN wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /usr/share/keyrings/adoptium.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" \
      > /etc/apt/sources.list.d/adoptium.list

RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y install \
      temurin-25-jdk \
      temurin-8-jdk

# Resolve the real install dirs and pin stable symlinks.
#   `ls -d` exits non-zero if the glob matches nothing, so a bad assumption
#   breaks `docker build` here instead of silently producing a broken JAVA_HOME.
RUN ln -sfn "$(ls -d /usr/lib/jvm/temurin-25-jdk*)" /usr/lib/jvm/temurin-25 && \
    ln -sfn "$(ls -d /usr/lib/jvm/temurin-8-jdk*)"  /usr/lib/jvm/temurin-8

# Run the Gradle daemon on JDK 25; Gradle finds JDK 8 as a toolchain
# via /usr/lib/jvm auto-detection (Gradle 9.5.1).
ENV JAVA_HOME=/usr/lib/jvm/temurin-25
ENV PATH="${JAVA_HOME}/bin:${PATH}"

RUN java -version && ls -1 /usr/lib/jvm

# Configure locale to UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

#  https://nodejs.org/en/about/previous-releases
#   * https://deb.nodesource.com/setup_20.x — Node.js 20 "Iron"
#   Pinned to Node 20: the web build still uses webpack 4.

# Install nodejs
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install --global npm@10.3.0
