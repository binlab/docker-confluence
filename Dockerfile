FROM openjdk:8u181-jdk-alpine3.8

LABEL maintainer="Mark <mark.binlab@gmail.com>"

ARG CONFLUENCE_SERVER_VERS=6.6.11
ARG PGSQL_JDBC_VERS=42.2.5
ARG MYSQL_JDBC_VERS=5.1.46

ARG CONFLUENCE_VAR=/var/atlassian/confluence
ARG CONFLUENCE_OPT=/opt/atlassian/confluence

ARG CONFLUENCE_SERVER_URL=https://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${CONFLUENCE_SERVER_VERS}.tar.gz
ARG PGSQL_JDBC_URL=https://jdbc.postgresql.org/download/postgresql-${PGSQL_JDBC_VERS}.jar
ARG MYSQL_JDBC_URL=https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_JDBC_VERS}.tar.gz

ARG USER=confluence
ARG GROUP=confluence
ARG UID=1024
ARG GID=1024

ENV LC_ALL=C \
    CONFLUENCE_HOME=$CONFLUENCE_VAR \
    CONFLUENCE_INSTALL=$CONFLUENCE_OPT

RUN addgroup -S -g ${GID} ${GROUP} \
    && adduser -S -D -H -s /bin/false -g "${USER} service" \
           -u ${UID} -G ${GROUP} ${USER} \
    && mkdir -p ${CONFLUENCE_VAR} \
           ${CONFLUENCE_OPT}/conf \
    && apk add --no-cache --virtual .build-deps \
           curl \
           tar \
    && apk add --no-cache \
           bash \
           fontconfig \
           ttf-dejavu \
    && curl -Ls "${CONFLUENCE_SERVER_URL}" \
           | tar -xz --directory "${CONFLUENCE_OPT}" \
               --strip-components=1 --no-same-owner \
    && cd ${CONFLUENCE_OPT}/confluence/WEB-INF/lib \
    && rm -f ./lib/postgresql-9.* \
    && curl -Os ${PGSQL_JDBC_URL} \
    && curl -Ls ${MYSQL_JDBC_URL} \
           | tar -xz --directory ${CONFLUENCE_OPT}/lib \
               --strip-components=1 --no-same-owner \
               mysql-connector-java-${MYSQL_JDBC_VERS}/mysql-connector-java-${MYSQL_JDBC_VERS}-bin.jar \
    && chmod -R 700 \
           ${CONFLUENCE_VAR} \
           ${CONFLUENCE_OPT}/conf \
           ${CONFLUENCE_OPT}/temp \
           ${CONFLUENCE_OPT}/logs \
           ${CONFLUENCE_OPT}/work \
    && chown -R ${USER}:${GROUP} \
           ${CONFLUENCE_VAR} \
           ${CONFLUENCE_OPT}/conf \
           ${CONFLUENCE_OPT}/temp \
           ${CONFLUENCE_OPT}/logs \
           ${CONFLUENCE_OPT}/work \
    && sed -i 's/JVM_MINIMUM_MEMORY="\(.*\)"/JVM_MINIMUM_MEMORY="${JVM_MINIMUM_MEMORY:=\1}"/g' ${CONFLUENCE_OPT}/bin/setenv.sh \
    && sed -i 's/JVM_MAXIMUM_MEMORY="\(.*\)"/JVM_MAXIMUM_MEMORY="${JVM_MAXIMUM_MEMORY:=\1}"/g' ${CONFLUENCE_OPT}/bin/setenv.sh \
    && echo -e "\nconfluence.home=${CONFLUENCE_VAR}" >> ${CONFLUENCE_OPT}/confluence/WEB-INF/classes/confluence-init.properties \
    && touch -d "@0" ${CONFLUENCE_OPT}/conf/server.xml \
    && apk del .build-deps

USER ${USER}

EXPOSE 8090/tcp

VOLUME ${CONFLUENCE_OPT}/logs
VOLUME ${CONFLUENCE_OPT}/conf
VOLUME ${CONFLUENCE_VAR}

WORKDIR ${CONFLUENCE_OPT}

CMD ["./bin/catalina.sh", "run"]
