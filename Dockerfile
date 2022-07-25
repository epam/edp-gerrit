FROM adoptopenjdk/openjdk11:alpine-jre

LABEL maintainer="SupportEPMD-EDP@epam.com"

# Overridable defaults
ENV GERRIT_HOME /var/gerrit
ENV GERRIT_SITE ${GERRIT_HOME}/review_site
ENV GERRIT_WAR ${GERRIT_HOME}/gerrit.war
ENV GERRIT_VERSION 3.6.1
ENV GERRIT_USER gerrit2
ENV GERRIT_INIT_ARGS "--install-all-plugins"

# Add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN adduser -D -h "${GERRIT_HOME}" -g "Gerrit User" -s /sbin/nologin "${GERRIT_USER}"

RUN set -x \
    && apk add --update --no-cache \
        bash=5.1.16-r0 \
        curl=7.79.1-r2 \
        git-gitweb=2.32.3-r0 \
        git=2.32.3-r0 \
        openssh-client=8.6_p1-r3 \
        openssl=1.1.1q-r0 \
        perl-cgi=4.51-r0 \
        perl=5.32.1-r0 \
        su-exec=0.2-r1

RUN mkdir /docker-entrypoint-init.d && \
    curl -fSsL https://gerrit-releases.storage.googleapis.com/gerrit-${GERRIT_VERSION}.war -o ${GERRIT_WAR}

#Download Plugins
ENV PLUGIN_VERSION=3.6
ENV GERRITFORGE_URL=https://gerrit-ci.gerritforge.com
ENV GERRITFORGE_ARTIFACT_DIR=lastSuccessfulBuild/artifact/bazel-bin/plugins

RUN for plugin in events-log oauth metrics-reporter-prometheus serviceuser; do \
        curl -fSsL "${GERRITFORGE_URL}/job/plugin-${plugin}-bazel-master-stable-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/${plugin}/${plugin}.jar" \
        -o "${GERRIT_HOME}/${plugin}.jar"; \
    done

# Ensure the entrypoint scripts are in a fixed location
COPY gerrit-entrypoint.sh /
COPY gerrit-start.sh /
RUN chmod +x /gerrit*.sh && \
    su-exec ${GERRIT_USER} mkdir -p $GERRIT_SITE

#Gerrit site directory is a volume, so configuration and repositories
#can be persisted and survive image upgrades.
VOLUME $GERRIT_SITE

ENTRYPOINT ["/gerrit-entrypoint.sh"]

EXPOSE 8080 29418

CMD ["/gerrit-start.sh"]
